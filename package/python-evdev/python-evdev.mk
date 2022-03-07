PYTHON_EVDEV_VERSION = master
PYTHON_EVDEV_SITE = $(call github,gvalkov,python-evdev,$(PYTHON_EVDEV_VERSION))
PYTHON_EVDEV_SETUP_TYPE = distutils

define PYTHON_EVDEV_BUILD_CMDS
    # make it python2-friendly 
    sed -i -e 's/super().close/super(InputDevice,self).close()/g' $(BUILD_DIR)/python-evdev-master/evdev/device.py
endef

$(eval $(python-package))
