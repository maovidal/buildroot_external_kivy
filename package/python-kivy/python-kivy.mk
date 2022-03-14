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

PYTHON_KIVY_DEPENDENCIES = host-python-cython
PYTHON_KIVY_DEPENDENCIES += sdl2 sdl2_image sdl2_mixer sdl2_ttf  # From oficial documentation.
PYTHON_KIVY_DEPENDENCIES += mtdev python-docutils python-pygments  # From oficial documentation.
PYTHON_KIVY_DEPENDENCIES += util-linux pango  # Otherwise build fails with some unidentified cases.

# Regarding compilation options.
# Inspecting build, those are avilable in Kivy 2.1.0
#  * use_rpi
#  * use_egl
#  * use_opengl_es2
#  * use_opengl_mock
#  * use_sdl2
#  * use_pangoft2
#  * use_ios
#  * use_android
#  * use_mesagl
#  * use_x11
#  * use_wayland
#  * use_gstreamer
#  * use_avfoundation
#  * use_osx_frameworks
#  * debug_gl
#  * kivy_sdl_gl_alpha_size
#  * debug
# Remark: USE_SDL seems to be deprecated in Kivy 2.1.0?

PYTHON_KIVY_ENV += USE_SDL2=1
PYTHON_KIVY_ENV += KIVY_SDL2_PATH=$(STAGING_DIR)/usr/include/SDL2  # Without this, build reports ERROR: unsafe header/library path used in cross-compilation: '-I/usr/local/include/SDL2'

#
## OpenGL or OpenGLES
#

ifeq ($(BR2_PACKAGE_HAS_LIBGL),y)
    PYTHON_KIVY_DEPENDENCIES += libgl
    # PYTHON_KIVY_ENV += USE_OPENGL_MOCK=1  # TODO: Should it be here? disable linking to libGL

else ifeq ($(BR2_PACKAGE_HAS_LIBGLES),y)
    PYTHON_KIVY_DEPENDENCIES += libgles
    PYTHON_KIVY_ENV += USE_OPENGL_ES2=1
    # PYTHON_KIVY_ENV += USE_OPENGL_MOCK=1  # disable linking to libGL
endif

#
## Window managers
#

ifeq ($(BR2_PACKAGE_HAS_LIBEGL),y)
    PYTHON_KIVY_DEPENDENCIES += libegl
    PYTHON_KIVY_ENV += USE_EGL=1
else
    PYTHON_KIVY_ENV += USE_EGL=0
endif

ifeq ($(BR2_PACKAGE_XLIB_LIBX11)$(BR2_PACKAGE_XLIB_LIBXRENDER),yy)
    PYTHON_KIVY_DEPENDENCIES += xlib_libX11 xlib_libXrender
    PYTHON_KIVY_ENV += USE_X11=1
else
    PYTHON_KIVY_ENV += USE_X11=0
endif

#
## Other configuration options for the build
#

# # TODO: Confirm if this is correct for USE_MESAGL introduced in Kivy 2.1.0
# ifeq ($(BR2_PACKAGE_MESA3D),y)
#     PYTHON_KIVY_DEPENDENCIES += mesa3d
#     PYTHON_KIVY_ENV += USE_MESAGL=1
# else
#     PYTHON_KIVY_ENV += USE_MESAGL=0
# endif

ifeq ($(BR2_PACKAGE_WAYLAND),y)
    PYTHON_KIVY_DEPENDENCIES += wayland
    PYTHON_KIVY_ENV += USE_WAYLAND=1
else
    PYTHON_KIVY_ENV += USE_WAYLAND=0
endif

ifeq ($(BR2_PACKAGE_PYTHON_KIVY_GSTREAMER),y)
    PYTHON_KIVY_DEPENDENCIES += gstreamer1
    PYTHON_KIVY_ENV += USE_GSTREAMER=1  # Should it be GSTREAMER (deprecated?) or GSTREAMER1
else
    PYTHON_KIVY_ENV += USE_GSTREAMER=0  # Should it be GSTREAMER (deprecated?) or GSTREAMER1
endif

# Raspberry Pi exclusive
ifeq ($(BR2_PACKAGE_PYTHON_KIVY_RPI),y)
    PYTHON_KIVY_DEPENDENCIES += rpi-userland
    # The next two (2) are based on https://github.com/kivy/kivy/pull/5866
    PYTHON_KIVY_ENV += KIVY_CROSS_PLATFORM=rpi
    PYTHON_KIVY_ENV += KIVY_CROSS_SYSROOT=${STAGING_DIR}
endif

define PYTHON_KIVY_REMOVE_EXAMPLES
    ifeq ($(BR2_PACKAGE_PYTHON_KIVY_EXAMPLES),n)
        rm -rf $(TARGET_DIR)/usr/share/kivy-examples
        echo "Kivy examples removed"
    endif
endef

PYTHON_KIVY_POST_INSTALL_TARGET_HOOKS += PYTHON_KIVY_REMOVE_EXAMPLES

$(eval $(python-package))
