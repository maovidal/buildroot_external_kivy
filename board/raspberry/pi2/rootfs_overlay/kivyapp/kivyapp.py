import os
# tell kivy a couple of home truths
os.environ['KIVY_GL_BACKEND']='gl'                                                                  
os.environ['HOME']='/root'

from kivy.app import App
from kivy.uix.button import Button

class TestApp(App):
    def build(self):
        return Button(text='Hello World')

TestApp().run()
