################################################################################
#
## kivy
#
#################################################################################

PYTHON_KIVY_VERSION = 2.1.0
PYTHON_KIVY_SITE = $(call github,kivy,kivy,$(PYTHON_KIVY_VERSION))
PYTHON_KIVY_SETUP_TYPE = distutils
PYTHON_KIVY_LICENSE = MIT
PYTHON_KIVY_LICENSE_FILES = LICENSE

#
## Required for Kivy compilation (either from documentation and experimentation)
#

PYTHON_KIVY_DEPENDENCIES = host-python-cython
PYTHON_KIVY_DEPENDENCIES += sdl2 sdl2_image sdl2_mixer sdl2_ttf  # From oficial documentation.
PYTHON_KIVY_DEPENDENCIES += mtdev python-docutils python-pygments  # From oficial documentation.
PYTHON_KIVY_DEPENDENCIES += util-linux pango  # Otherwise build fails in some unidentified cases.
PYTHON_KIVY_ENV += USE_SDL2=1
PYTHON_KIVY_ENV += KIVY_SDL2_PATH=$(STAGING_DIR)/usr/include/SDL2  # Without this, build reports ERROR: unsafe header/library path used in cross-compilation: '-I/usr/local/include/SDL2'

#
## OpenGL or OpenGLES
#

ifeq ($(BR2_PACKAGE_HAS_LIBGL),y)
    PYTHON_KIVY_DEPENDENCIES += libgl
    PYTHON_KIVY_ENV += USE_OPENGL_MOCK=0
else ifeq ($(BR2_PACKAGE_HAS_LIBGLES),y)
    PYTHON_KIVY_DEPENDENCIES += libgles
    PYTHON_KIVY_ENV += USE_OPENGL_ES2=1
    PYTHON_KIVY_ENV += USE_OPENGL_MOCK=1  # disable linking to libGL
endif

#
## Mesa
#

ifeq ($(BR2_PACKAGE_MESA3D),y)
    PYTHON_KIVY_DEPENDENCIES += mesa3d
    # TODO: Seems there is a bug in Kivy 2.1.0
    ##  USE_MESAGL=1 fails providing this error while building:
    ##  kivy/graphics/cgl_backend/cgl_debug.c:5997:123: error: expected identifier before ‘;’ token
    ##  5997 |   __pyx_v_4kivy_8graphics_11cgl_backend_9cgl_debug_cgl_native->glBlendEquationSeparate(__pyx_v_modeRGB, __pyx_v_modeAlpha);
    # We leave it without this option.
    PYTHON_KIVY_ENV += USE_MESAGL=0
    # PYTHON_KIVY_ENV += USE_MESAGL=1
else
    PYTHON_KIVY_ENV += USE_MESAGL=0
endif

#
## EGL
#

ifeq ($(BR2_PACKAGE_HAS_LIBEGL),y)
    PYTHON_KIVY_DEPENDENCIES += libegl
    PYTHON_KIVY_ENV += USE_EGL=1
else
    PYTHON_KIVY_ENV += USE_EGL=0
endif

#
## X11
#

ifeq ($(BR2_PACKAGE_XLIB_LIBX11)$(BR2_PACKAGE_XLIB_LIBXRENDER),yy)
    PYTHON_KIVY_DEPENDENCIES += xlib_libX11 xlib_libXrender xserver_xorg-server
    PYTHON_KIVY_ENV += USE_X11=1
else
    PYTHON_KIVY_ENV += USE_X11=0
endif

#
## Wayland
#

ifeq ($(BR2_PACKAGE_WAYLAND),y)
    PYTHON_KIVY_DEPENDENCIES += wayland
    PYTHON_KIVY_ENV += USE_WAYLAND=1
else
    PYTHON_KIVY_ENV += USE_WAYLAND=0
endif

#
## Optional GStreamer
#

ifeq ($(BR2_PACKAGE_PYTHON_KIVY_GSTREAMER),y)
    PYTHON_KIVY_DEPENDENCIES += gstreamer1
    PYTHON_KIVY_ENV += USE_GSTREAMER=1  # Should it be GSTREAMER (deprecated?) or GSTREAMER1?
else
    PYTHON_KIVY_ENV += USE_GSTREAMER=0  # Should it be GSTREAMER (deprecated?) or GSTREAMER1?
endif

#
## Raspberry Pi exclusive
#

ifeq ($(BR2_PACKAGE_PYTHON_KIVY_RPI),y)
    PYTHON_KIVY_DEPENDENCIES += rpi-userland
    # The next two (2) are based on https://github.com/kivy/kivy/pull/5866
    PYTHON_KIVY_ENV += KIVY_CROSS_PLATFORM=rpi
    PYTHON_KIVY_ENV += KIVY_CROSS_SYSROOT=${STAGING_DIR}
endif

#
## Optional examples
#

define PYTHON_KIVY_REMOVE_EXAMPLES
    # TODO: This comparison does not work as BR2_PACKAGE_PYTHON_KIVY_EXAMPLES is not available when called resulting in the error: `ifeq (,y)'
    # ifeq ($(BR2_PACKAGE_PYTHON_KIVY_EXAMPLES),y)
    #     echo "Kivy examples left at /usr/share/kivy-examples"
    # else
    #     rm -rf $(TARGET_DIR)/usr/share/kivy-examples
    #     echo "Kivy examples removed"
    # endif
    # It removes the examples anyway.
    rm -rf $(TARGET_DIR)/usr/share/kivy-examples
    echo "Kivy examples removed"
endef

PYTHON_KIVY_POST_INSTALL_TARGET_HOOKS += PYTHON_KIVY_REMOVE_EXAMPLES

$(eval $(python-package))
