This is an attempt to create a Kivy package for Buildroot.

To get an idea of what components are involved in a compilation, here there is
an overview of Kivy's architecture:
https://kivy.org/doc/stable/guide/architecture.html

While this package aims to effectively build the basic Kivy package based on the
official requirements the idea is to extend it to other common package
selections providing options over the base package.

This is a work in progress, and so far has been produced with my limited
knowledge about all the software involved. I'm willing to learn and hopefully
be of help to others. This repo is open to pull requests.

On the code, the parts that need more attention are tagged with the word TODO:


# Kivy compilation options

For reference, the current 2.1.0, while building reports these options:

 * use_rpi
 * use_egl
 * use_opengl_es2
 * use_opengl_mock
 * use_sdl2
 * use_pangoft2
 * use_ios
 * use_android
 * use_mesagl
 * use_x11
 * use_wayland
 * use_gstreamer
 * use_avfoundation
 * use_osx_frameworks
 * debug_gl
 * kivy_sdl_gl_alpha_size
 * debug

*Remark: USE_SDL seems to be deprecated in Kivy 2.1.0*


# Packages that may be useful or yet to evaluate:

BR2_PACKAGE_XSERVER_XORG_SERVER_XVFB  # Frame buffer?
BR2_PACKAGE_XDRIVER_XF86_VIDEO_FBDEV  # framebuffer device video driver for the Xorg X server
BR2_PACKAGE_XDRIVER_XF86_INPUT_EVDEV  # To determine if required
BR2_PACKAGE_SDL2_KMSDRM  # Can be of any bennefit?
BR2_PACKAGE_WAYLAND  # Option to X11?
BR2_PACKAGE_LIBGLVND  # Provides the gl.h
