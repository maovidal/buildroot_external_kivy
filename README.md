# Intro

**Work in progress**

**Help and pull requests are welcome**

This implements Buildroot's mechanism [BR2_EXTERNAL tree][DOC_BR2_EXTERNAL] to build an image that runs a `Kivy` app.
Currently `Raspberry Pi2` and `Intel Stick STK1AW32SC` have been tested.

Part of the content of this repo has been based on [this great post that shows how to build Kivy running on a RP2][evgueni_post] by [evgueni][evgueni].


# Quick setup:

Besides using this repo in your existing Buildroot installation using the [external mechanism][br2_external], there is also the option to use this [docker-buildroot repo][docker_buildroot] that provides a fast and convenient way to start working right away.

Those are the instructions for the later case:

1. Get a clone of [docker-buildroot][docker_buildroot]:

``` shell
git clone https://github.com/vidalastudillo/docker-buildroot
```

2. Get a clone of this repo to be placed at the folder `externals/kivy`:

``` shell
git clone https://github.com/MrMauro/buildroot_external-kivy externals/kivy
```

3. Build the Docker image:

``` shell
docker build -t "advancedclimatesystems/buildroot" .
```

4. Create a [data-only container][data-only]:

``` shell
docker run -i --name buildroot_output advancedclimatesystems/buildroot /bin/echo "Data only."
```

This container has 2 volumes at `/root/buildroot/dl` and `/buildroot_output`.
Buildroot downloads all data to the first volume, the last volume is used as build cache, cross compiler and build results.

5. Setup the new external folder and load the default configuration:

``` shell
./scripts/run.sh make BR2_EXTERNAL=/root/buildroot/externals/kivy menuconfig
```

For Raspberry Pi 2:

``` shell
./scripts/run.sh make rpi2_defconfig
```

For Intel Stick:

``` shell
./scripts/run.sh make intelstick_defconfig
```

These are the two relevant folders on your host:

- `external/kivy`: the new external folder with the configs and other related files.
- `images`: with your valuable results.

Also, the `target` folder is provided just to ease checking the building process.

# Usage

A small script has been provided to make using the container a little easier.
It's located at the folder `scripts/run.sh`.

Then you can use usual commands like this:

``` shell
./scripts/run.sh make menuconfig
./scripts/run.sh make linux-rebuild
./scripts/run.sh make linux-menuconfig
./scripts/run.sh make all
```


# Configurations available

The following configurations are available that have been being implemented while following [this post that shows how to build Kivy running on a RP2][evgueni_post].

The shell commands here use the `run.sh` script in case the [docker-buildroot][docker-buildroot] is used. Otherwise in a normal Buildroot installation, those are meant to be issued without `./scripts/run.sh`

**myrpi2_defconfig**

The basic image:
- Starting point.

``` shell
./scripts/run.sh make clean all
./scripts/run.sh make myrpi2_defconfig
./scripts/run.sh make
```

**myrpi2_splash_defconfig**

(Not working yet, splash does not work)

New from previous configuration `myrpi2_defconfig`:
- Splash screen, means of customizing image assembly - used to effect "silent" boot 

Modified from original post:
- Modified `post-image.sh` from the buildroot original.
- Modified `cmdline.txt` from the post original, to include missing splash.
- Changed kernel version:
    BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM_5_10=y
    BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION="$(call github,raspberrypi,linux,581049d718caf95f5feb00607ac748d5841cf27c)/linux-581049d718caf95f5feb00607ac748d5841cf27c.tar.gz"
- Added (Build failed as bootcode.bin was not created):
    BR2_PACKAGE_RPI_FIRMWARE_BOOTCODE_BIN=y
    BR2_PACKAGE_RPI_FIRMWARE_VARIANT_PI=y

``` shell
./scripts/run.sh make clean all
./scripts/run.sh make myrpi2_splash_defconfig
./scripts/run.sh make
```

**myrpi2_splash_kivy_defconfig**

(splash does not work, yet)

New from previous configuration `myrpi2_splash_defconfig`:
- THUMB2 instruction set and MUSL LIBC, intention being to reduce image size and speed up cold boot
- /dev creation with eudev
- root login via SSH (pwd "raspberry")
- python3 + kivy

Modified from original post:
- Same from configuration `myrpi2_splash_defconfig`

``` shell
./scripts/run.sh make clean all
./scripts/run.sh make myrpi2_splash_kivy_defconfig
./scripts/run.sh make
```

**myrpi2_kivy_rofs_defconfig**

(splash does not work, yet)
(kivy app does not work, yet. No logs. It may be related to i2c-dev not present on etc/modules )

New from previous configuration `myrpi2_splash_kivy_defconfig`:
- read-only file system
- usb storage FAT and NTFS
- h/w pwm
- quadrature encoder input
- I2C, SPI

Modified from original post:
- Same from configuration `myrpi2_splash_kivy_defconfig`

``` shell
./scripts/run.sh make clean all
./scripts/run.sh make myrpi2_kivy_rofs_defconfig
./scripts/run.sh make
```

## Saving configs

A modified configuration can be saved using something like this (replacing the text '<mycustom>'):

```shell
./scripts/run.sh make BR2_DEFCONFIG=/root/buildroot/externals/kivy/configs/<mycustom>_defconfig savedefconfig
```

[br2_external]:http://buildroot.uclibc.org/downloads/manual/manual.html#outside-br-custom
[DOC_BR2_EXTERNAL]:https://buildroot.org/downloads/manual/manual.html#customize-dir-structure
[evgueni]:https://forums.raspberrypi.com/memberlist.php?mode=viewprofile&u=208985&sid=be8a772e5aef87a4991576d69e510cce
[evgueni_post]:https://forums.raspberrypi.com/viewtopic.php?t=307052&sid=b8bbc7d25cf2b58cb6d4a35edd716d6a
[docker-buildroot]:https://github.com/vidalastudillo/docker-buildroot
