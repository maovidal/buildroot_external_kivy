#!/usr/bin/env python

# tell kivy a couple of home truths
import os
os.environ['KIVY_GL_BACKEND']='gl'                                                                  
os.environ['HOME']='/root'

from kivy.app import App
from kivy.uix.gridlayout import GridLayout
from kivy.uix.button import Button
from kivy.uix.togglebutton import ToggleButton
from kivy.lang import Builder
from kivy.clock import Clock
from kivy.properties import BoundedNumericProperty
from kivy.properties import ObjectProperty
from kivy.properties import StringProperty
from kivy.properties import BooleanProperty
from kivy.properties import DictProperty
import evdev
import pyudev
from threading import Thread
import datetime
import RPi.GPIO as GPIO
import json
from pwm import PWM
from ADCDACPi import ADCDACPi

pwr_GPIO = 18 # emergency shutdown signal
led_GPIO = 22 # LED
pb_GPIO = 17 # encoder pushbutton switch
# quadrature encoder GPIO 23, 24 assigned in config.txt
# pwm GPIO 12, 13 assigned in config.txt
countdown_s = 30 # backlight dimming
minbacklight = 25
usbport = '4'

Builder.load_string('''
#: kivy 1.11.0
#: import Clock kivy.clock.Clock

<SelectButton@ToggleButton>:
    group: "mygroup"
    paramset: 
    param:
    on_press:
        self.parent.do_selection(self)

<MainWidget>:
    cols: 3
    SelectButton:
        paramset: root.timecats
        markup: True
        text: root.displaytime
    SelectButton:
        paramset: 'pwmfreq1', 'pwmduty1', 'pwmfreq2', 'pwmduty2'
        markup: True
        text: root.pwmparams
    SelectButton:
        paramset: 'led',
        text: "LED " + ("ON" if root.led else "OFF")
        on_press:
            root.led = not root.led if 'down' in self.state else root.led
        on_release:
            self.state = 'normal'
    SelectButton:
        paramset: 'brightness',
        text: "backlight: " + str(root.brightness)
    SelectButton:
        paramset: 'dacvolts',
        text: "DAC: " + '{:.2f}'.format(root.dacvolts) + "V\\nADC: " + root.adcvolts + " V"
    ToggleButton:
        text: "Save Config" if 'normal' in self.state else "Saving.."
        disabled: False if root.usbmediapath else True
        on_press:
            Clock.schedule_once(lambda dt: root.save_config(self), root.blnkfni)
''')
                
class MainWidget(GridLayout):

    brightness = BoundedNumericProperty(255, min=minbacklight, max=255, errorhandler=lambda x: 255 if x > 255 else minbacklight)
    pwmfreq1 = BoundedNumericProperty(1000, min=10, max=10000, errorhandler=lambda x: 10000 if x > 10000 else 10)
    pwmduty1 = BoundedNumericProperty(50, min=0, max=100, errorhandler=lambda x: 100 if x > 100 else 0)
    pwmfreq2 = BoundedNumericProperty(1000, min=10, max=10000, errorhandler=lambda x: 10000 if x > 10000 else 10)
    pwmduty2 = BoundedNumericProperty(50, min=0, max=100, errorhandler=lambda x: 100 if x > 100 else 0)
    dacvolts = BoundedNumericProperty(1.5, min=0, max=3.2999, errorhandler=lambda x: 3.2999 if x > 3.2999 else 0)
    adcvolts = StringProperty()
    selection = ObjectProperty(allownone=True)
    _displaytime = ObjectProperty()
    displaytime = StringProperty()
    pwmparams = StringProperty()
    usbmediapath = StringProperty(allownone=True)
    led = BooleanProperty()
    timecats = 'years', 'months', 'days', 'hours', 'minutes', 'seconds'
    blnkfni = .1 #seconds
    
    def __init__(self, **kwargs):
        super(MainWidget, self).__init__(**kwargs)
        
        self.do_backlight() 
        for device in [evdev.InputDevice(path) for path in evdev.list_devices()]:
            if 'rotary' in device.name:
                self.encoder_dev=device
                break
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(pb_GPIO, GPIO.IN, pull_up_down=GPIO.PUD_UP)
        GPIO.add_event_detect(pb_GPIO, GPIO.FALLING, callback=self.pb_handler)     
        GPIO.setup(led_GPIO, GPIO.OUT)
        GPIO.output(led_GPIO, GPIO.LOW)
        GPIO.setup(25, GPIO.OUT)  # LDAC pin of MCP4822 on ADC-DAC Pi Zero board
        GPIO.output(25, GPIO.LOW)
        GPIO.setup(pwr_GPIO, GPIO.IN,  pull_up_down=GPIO.PUD_UP)
        GPIO.add_event_detect(pwr_GPIO, GPIO.RISING, callback=self.pwrdwn)         
        
        self.pwm1 = PWM(0)
        self.pwm2 = PWM(1)
        self.pwm1.export()
        self.pwm2.export()        
        self.bind(_displaytime=self.update_displaytime)
        self.bind(pwmfreq1 = lambda *args: self.update_pwmparams())
        self.bind(pwmduty1 = lambda *args: self.update_pwmparams())
        self.bind(pwmfreq2 = lambda *args: self.update_pwmparams())
        self.bind(pwmduty2 = lambda *args: self.update_pwmparams())
        self.bind(dacvolts = lambda *args: self.do_dac())
        self.bind(led = lambda obj, val: self.toggle_led(val))
        Clock.schedule_interval(self.poll_encoder, .05)
        os.system("/sbin/hwclock --hctosys --noadjfile --utc") # util-lunux hwclock because it can cope with ro fs
        self._displaytime = datetime.datetime.now()
        self.update_pwmparams()
        self.tick()
        usbmon=Thread(target=self.usb_monitor)
        usbmon.daemon=True
        usbmon.start()
        self.adcdac = ADCDACPi(2) # DAC gain set to 2 for 3V3 max output
        self.adcdac.set_adc_refvoltage(3.29)
        self.do_dac()
        
    def on_touch_down(self, touch): 
        self.do_backlight()
        return super(self.__class__, self).on_touch_down(touch)
      

    def poll_encoder(self, dt):
        try:
            for event in self.encoder_dev.read():
                if event.type == evdev.ecodes.EV_REL:
                    self.handle_encoder(event.value)
        except:
            pass # need this because absence of event results in exception
    
    def handle_encoder(self, direction):
        if self.selection.param:
            if not self.selection.param in self.timecats:
                if isinstance (self.property(self.selection.param), BoundedNumericProperty): # ignore boolean   
                    valuediff = direction*(self.property(self.selection.param).get_max(self)-self.property(self.selection.param).get_min(self))//100
                    self.property(self.selection.param).set(self, self.property(self.selection.param).get(self)+valuediff)
            else: # adjusting date/time
                self.do_datetime(direction)
        self.do_backlight()
        
    def pb_handler(self, gpio_or_dt):
        if gpio_or_dt is pb_GPIO: # call resulting from callback binding
            Clock.unschedule(self.pb_handler) # unschedule previous calls
            Clock.schedule_once(self.pb_handler, 0.01) # debounce
        else: # scheduled by itself earlier 
            if GPIO.input(pb_GPIO) == 0 and self.selection:
                self.selection.param = self.selection.paramset[(self.selection.paramset.index(self.selection.param) + 1) % len(self.selection.paramset)]
                self.update_displaytime()
                self.update_pwmparams()
                self.do_backlight()
    
    def do_selection(self, tb):
        # detect deselection of datetime
        tistime = (tb.paramset is self.timecats and 'normal' in tb.state) \
                    or (((self.selection.paramset if self.selection else None) is self.timecats) and (not tb.paramset is self.timecats))
        tb.param = tb.paramset[0] if 'down' in tb.state else None
        self.selection = tb if 'down' in tb.state else None
        self.update_displaytime()
        self.update_pwmparams()
        self.do_dac()
        if tistime:
            self.align_clocks()
    
    def do_backlight(self, dt=0):
        if dt:
            os.system("echo " + str(minbacklight) + " > /sys/class/backlight/rpi_backlight/brightness")
        else:
            Clock.unschedule(self.do_backlight)
            os.system("echo " + str(self.brightness) + " > /sys/class/backlight/rpi_backlight/brightness")
            Clock.schedule_once(self.do_backlight, countdown_s)
            
    def do_datetime(self, direction, timecat = None):
        timecat = timecat if timecat else self.selection.param
        if 'seconds' in timecat:
            self.tick()
            self._displaytime = self._displaytime.replace(second=(self._displaytime + datetime.timedelta(seconds=direction)).second)
        elif 'minutes' in timecat:
            self._displaytime = self._displaytime.replace(minute=(self._displaytime + datetime.timedelta(minutes=direction)).minute)
        elif 'hours' in timecat:
            self._displaytime = self._displaytime.replace(hour=(self._displaytime + datetime.timedelta(hours=direction)).hour)
        elif 'days' in timecat:
            day=(self._displaytime.day-1+direction) % 31 + 1 # wrap around 1-31 range
            try:
                self._displaytime = self._displaytime.replace(day=day)
            except ValueError: # day out of range for month, cycle on to next acceptable day
                self.do_datetime(direction + direction / abs(direction), 'days')
        elif 'months' in timecat:
            month=(self._displaytime.month-1+direction) % 12 + 1 # wrap around 1-12 range
            try:
                self._displaytime=self._displaytime.replace(month=month)
            except ValueError: # day is out of range for the new month
                self._displaytime = self._displaytime.replace(month=month, day=1)
                self.do_datetime(-1, 'days')
        elif 'years' in timecat:
            try:
                self._displaytime=self._displaytime.replace(year=self._displaytime.year+direction)
            except ValueError: # 29 Feb in non-leap year
                self._displaytime=self._displaytime.replace(year=self._displaytime.year+direction, day=28)  
        os.system("date -s "+self._displaytime.strftime("%Y.%m.%d-%H:%M:%S")+" >/dev/null") # system clock
        
    def update_pwmparams(self):
        def location(str,substr,occurance):
            location = -1
            for i in range(0,occurance):
                location = str.find(substr, location+1) + 1
            return location        
            
        self.pwmparams = "PWM1: " + str(self.pwmfreq1) + "Hz / " + str(self.pwmduty1) + "%\nPWM2: " \
                        + str(self.pwmfreq2) + "Hz / " + str(self.pwmduty2) + "%"
        start, end = None, None
        if 'pwm' in (self.selection.param if self.selection else ''):
            if 'freq' in self.selection.param:
                start = location(self.pwmparams, ':', int(self.selection.param[-1]))
                end = location(self.pwmparams, 'z', int(self.selection.param[-1]))
            else: # duty
                start = location(self.pwmparams, '/', int(self.selection.param[-1]))
                end = location(self.pwmparams, '%', int(self.selection.param[-1]))
        if start != end:
            self.pwmparams=self.pwmparams[0:start]+'[b][size=25]'+self.pwmparams[start:end]+'[/b][/size]'+self.pwmparams[end:]
        pwm_on = 'pwm' in (self.selection.param if self.selection else '')
        self.do_pwm(self.pwmfreq1, self.pwmduty1 if pwm_on else 0, self.pwmfreq2, self.pwmduty2 if pwm_on else 0)    
        
    def do_pwm(self,pwm1freq,pwm1duty,pwm2freq,pwm2duty):
        # TO AVOID "IOError: [Errno 22] Invalid argument" ENSURE THAT DUTY < PERIOD, ALWAYS SET DUTY=0 THEN PERIOD THEN DUTY=ACTUAL
        def set_pwm(pwmchan,freq,duty):
            freq = freq if freq else 1. # always set to something sensible
            if pwmchan.duty_cycle == pwmchan.period: # boot condition, both zero
                pwmchan.period = 1000 # an arbitrary valid setting
            pwmchan.duty_cycle=0 # avoid possibility of dyty_cycle >= period
            period_ns=int(round(1./freq*1e9)) # convert frequency from Hz to period in ns
            pulse_ns=int(round(period_ns*duty)) # convert duty from fraction to time in ns
            # pwm driver does not like 100% duty, have the potty ready
            inverted = False if period_ns > pulse_ns else True
            pulse_ns = pulse_ns if period_ns > pulse_ns else 0 
            pwmchan.inversed = inverted
            pwmchan.period = period_ns
            pwmchan.duty_cycle = pulse_ns
            pwmchan.enable = True if duty else False     

        set_pwm(self.pwm1,pwm1freq,pwm1duty/100.)
        set_pwm(self.pwm2,pwm2freq,pwm2duty/100.)
            
    def do_dac(self):
        # remember to turn off when unselected
        if 'dac' in (self.selection.param if self.selection else ''):
            self.adcdac.set_dac_voltage(1, self.dacvolts) # channel, setpoint
        else:
            self.adcdac.set_dac_voltage(1, 0) # channel, setpoint
        self.adcvolts = '{:.2f}'.format(self.adcdac.read_adc_voltage(2,0))
            
    def tick(self, dt=None):
        if dt: # scheduled by itself
            self._displaytime+=datetime.timedelta(seconds=1)
        else: # new tickoffset
            Clock.unschedule(self.tick)
            self.tickoffset = max(datetime.datetime.now().microsecond, 50000) # prevent irregular beat 
        Clock.schedule_once(self.tick, 1.0 - (datetime.datetime.now().microsecond - self.tickoffset)/1000000.) # compensate for drift
            
    def update_displaytime(self, prop=None, val=None):
        displaytime = self._displaytime.strftime("%Y-%m-%d %H:%M:%S")  + "\n\n" + self._displaytime.strftime('%A')
        start, end = None, None
        if (self.selection.param if self.selection else '') in self.timecats:
            if self.selection.param in self.timecats[0]: #year
                start, end = 0, 4
            else:
                start = 2 + self.selection.paramset.index(self.selection.param) * 3
                end =  start + 2        
        if start != end:
            displaytime=displaytime[0:start]+'[b][size=25]'+displaytime[start:end]+'[/b][/size]'+displaytime[end:]
        self.displaytime=displaytime      

    def align_clocks(self, dt=None):
        if dt is None:
            Clock.schedule_once(self.align_clocks, self.blnkfni) # maintain illusion of instant response
        else:
            os.system("date -s "+self._displaytime.strftime("%Y.%m.%d-%H:%M:%S")+" >/dev/null") # system clock
            os.system("hwclock -w") # sync hwclock with system  clock   
            
    def toggle_led(self, value):
        GPIO.output(led_GPIO, GPIO.HIGH if value else GPIO.LOW)
            
    def usb_monitor(self):
        context = pyudev.Context()
        monitor = pyudev.Monitor.from_netlink(context)
        monitor.filter_by(subsystem='block')
        monitor.start()
        
        def isStorageMedia(device, usbport):
            if 'ID_FS_TYPE' in device: # i.e. storage media
                #consider only conventinally formatted usb media in specified port (valid ports are 2-5)
                if any(x in device.get('ID_FS_TYPE') for x in ['vfat','ntfs']) and all(x in str(device) for x in ['usb','1-1.'+usbport]):
                    return device.get('DEVNAME')
                    
        for device in context.list_devices(subsystem='block', DEVTYPE='partition'):
            path = isStorageMedia(device, usbport)
            if path:
                self.load_config(path)
                break
        self.usbmediapath = path
        
        for device in iter(monitor.poll, None):
            path = isStorageMedia(device, usbport)
            if path:
                if device.action == 'add':
                    self.usbmediapath = path
                elif device.action == 'remove':
                    self.usbmediapath = None
                
    def save_config(self, tb):
        config = {}
        for child in self.children:
            if isinstance(child, ToggleButton) and hasattr(child, 'paramset'):
                if child.paramset is not self.timecats:
                    for param in child.paramset:
                        config[param] = self.property(param).get(self)
        if self.usbmediapath and not os.path.ismount("/media/usbdrv"):
            os.system("mount " + self.usbmediapath + " /media/usbdrv")
            with open('/media/usbdrv/config.json','w') as configfile:    
                json.dump(config, configfile, indent=4, sort_keys=True)
        # play safe
        if os.path.ismount("/media/usbdrv"):
            os.system("umount /media/usbdrv")
        tb.state = 'normal'
        
    def load_config(self, usbmediapath):
        if usbmediapath and not os.path.ismount("/media/usbdrv"):
            os.system("mount " + usbmediapath + " /media/usbdrv")        
            try:
                for name, value in json.load(open('/media/usbdrv/config.json')).items():
                    self.property(name).set(self,value)
            except:
                pass # keep defaults
        if os.path.ismount("/media/usbdrv"):
            os.system("umount /media/usbdrv")
            
    def pwrdwn(self, arg): # emergency shutdown
        if arg == pwr_GPIO: # RPI.GPIO callback
            Clock.unschedule(self.pwrdwn)
            Clock.schedule_once(self.pwrdwn, 0.005) # debounce to avoid spurious operation
            return
        if GPIO.input(pwr_GPIO): # signal is real
            print("<<<EMERGENCY SHUTDOWN TRIGGERED>>>")
            os.system("echo 1 > /sys/class/backlight/rpi_backlight/bl_power") # buy time
            os.system("umount -fr /media/usbdrv && poweroff -f")
            # apparently "unmounts" a mounted filesystem, informing the system to complete
            # any pending read or write operations, and safely detaching it
        
class MyApp(App):
    def build(self):
        return MainWidget()
   
if __name__ == '__main__':
    MyApp().run()
