################################################################################
#
## kivy
## https://forums.raspberrypi.com/viewtopic.php?t=307052
## https://forums.raspberrypi.com/viewtopic.php?t=242588
## http://lists.busybox.net/pipermail/buildroot/2019-June/253526.html
#
#################################################################################

PYTHON_KIVY_VERSION = 2.1.0
PYTHON_KIVY_SITE = $(call github,kivy,kivy,$(PYTHON_KIVY_VERSION))
PYTHON_KIVY_SETUP_TYPE = distutils
PYTHON_KIVY_LICENSE = MIT
PYTHON_KIVY_LICENSE_FILES = LICENSE

PYTHON_KIVY_DEPENDENCIES = host-python-cython

# From: https://kivy.org/doc/stable/api-kivy.graphics.cgl.html
# Unix available GL backends: gl, sdl2

# TESTING: Intel with GL
ifeq ($(BR2_PACKAGE_HAS_LIBGL),y)
    PYTHON_KIVY_DEPENDENCIES += libgl
    # PYTHON_KIVY_ENV += USE_OPENGL_ES2=1
    # From https://kivy.org/doc/stable/api-kivy.graphics.cgl.html
    PYTHON_KIVY_ENV += USE_OPENGL_MOCK=1
endif

ifeq ($(BR2_PACKAGE_HAS_LIBGLES),y)
    PYTHON_KIVY_DEPENDENCIES += libgles
    PYTHON_KIVY_ENV += USE_OPENGL_ES2=1
    # disable linking to libGL
    PYTHON_KIVY_ENV += USE_OPENGL_MOCK=1
endif

ifeq ($(BR2_PACKAGE_HAS_LIBEGL),y)
    PYTHON_KIVY_DEPENDENCIES += libegl
    PYTHON_KIVY_ENV += USE_EGL=1
    # From https://kivy.org/doc/stable/api-kivy.graphics.cgl.html
    PYTHON_KIVY_ENV += USE_OPENGL_MOCK=1
else
    PYTHON_KIVY_ENV += USE_EGL=0
endif

# From BR2_PACKAGE_GSTREAMER to BR2_PACKAGE_GSTREAMER1
# ifeq ($(BR2_PACKAGE_GSTREAMER1),y)
ifeq ($(BR2_PACKAGE_GSTREAMER),y)
    PYTHON_KIVY_DEPENDENCIES += gstreamer1
    PYTHON_KIVY_ENV += USE_GSTREAMER=1
else
    PYTHON_KIVY_ENV += USE_GSTREAMER=0
endif

ifeq ($(BR2_PACKAGE_SDL2)$(BR2_PACKAGE_SDL2_IMAGE)$(BR2_PACKAGE_SDL2_MIXER)$(BR2_PACKAGE_SDL2_TTF),yyyy)
    PYTHON_KIVY_DEPENDENCIES += sdl2 sdl2_image sdl2_mixer sdl2_ttf
    PYTHON_KIVY_ENV += USE_SDL2=1
    # Without this there is an ERROR: unsafe header/library path used in cross-compilation: '-I/usr/local/include/SDL2'
    PYTHON_KIVY_ENV += KIVY_SDL2_PATH=$(STAGING_DIR)/usr/include/SDL2
else
    PYTHON_KIVY_ENV += USE_SDL2=0
endif

ifeq ($(BR2_PACKAGE_WAYLAND),y)
    PYTHON_KIVY_DEPENDENCIES += wayland
    PYTHON_KIVY_ENV += USE_WAYLAND=1
else
    PYTHON_KIVY_ENV += USE_WAYLAND=0
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBX11)$(BR2_PACKAGE_XLIB_LIBXRENDER),yy)
    PYTHON_KIVY_DEPENDENCIES += xlib_libX11 xlib_libXrender
    PYTHON_KIVY_ENV += USE_X11=1
else
    PYTHON_KIVY_ENV += USE_X11=0
endif

# Raspberry Pi exclusive (At least for Pi2)
# TODO: Find a better way to determine a Raspberry Pi
ifeq ($(BR2_arm)$(BR2_cortex_a7)$(BR2_ARM_FPU_NEON_VFPV4),yyy)
    PYTHON_KIVY_DEPENDENCIES += rpi-userland
    # The next two (2) are based on https://github.com/kivy/kivy/pull/5866
    PYTHON_KIVY_ENV += KIVY_CROSS_PLATFORM=rpi
    PYTHON_KIVY_ENV += KIVY_CROSS_SYSROOT=${STAGING_DIR}
endif

define PYTHON_KIVY_REMOVE_EXAMPLES
    rm -rf $(TARGET_DIR)/usr/share/kivy-examples
endef

PYTHON_KIVY_POST_INSTALL_TARGET_HOOKS += PYTHON_KIVY_REMOVE_EXAMPLES

$(eval $(python-package))


# Build configuration is:
#  * use_rpi = 0
#  * use_egl = 0 OK
#  * use_opengl_es2 = 0 OK con duda
#  * use_opengl_mock = 0 OK con duda
#  * use_sdl2 = 1 OK
#  * use_pangoft2 = 0
#  * use_ios = 0
#  * use_android = 0
#  * use_mesagl = 0
#  * use_x11 = 0 OK
#  * use_wayland = 0 OK
#  * use_gstreamer = 1 OK con duda
#  * use_avfoundation = 0
#  * use_osx_frameworks = 0
#  * debug_gl = 0
#  * kivy_sdl_gl_alpha_size = 8
#  * debug = False
