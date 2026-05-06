# Intro

*⚠️ Help and pull requests are welcome ⚠️*

The purpose of this repo is to use `Buildroot` to produce images that run a
`Kivy` app. Currently `Raspberry Pi Compute Module 4` has been tested and is
working.

This repo is meant to be used implementing Buildroot's
[BR2_EXTERNAL tree][DOC_BR2_EXTERNAL] mechanism.


# Quick setup

Besides using this repo in your existing Buildroot installation using the
[external mechanism][br2_external], there is also the option to use this
[docker-buildroot repo][docker_buildroot] that provides a fast and convenient
way to start working right away.

1. Clone [docker-buildroot][docker_buildroot]:

```shell
git clone https://github.com/vidalastudillo/docker-buildroot
cd docker-buildroot
```

2. Set up the Buildroot source:

```shell
./scripts/bootstrap.sh
```

See [`BUILDROOT_VERSION`](https://github.com/vidalastudillo/docker-buildroot#buildroot-source-buildroot_version) in `docker-buildroot` for the configured fork and branch, or to use a different one.

3. Clone this repo into `externals/kivy`:

```shell
git clone https://github.com/maovidal/buildroot_external_kivy externals/kivy
```

4. Build the shared Docker image (once):

```shell
docker buildx build -t va_buildroot .
```

These are the relevant folders on your host:

- `externals/kivy/`: the external tree with configs and related files.
- `images/kivy/`: build outputs.
- `target/kivy/`: unpacked root filesystem for inspection.


# Buildroot usage

A run script is provided at `externals/kivy/run_cm4.sh`. It must always be
called from the root of the `docker-buildroot` project:

```shell
./externals/kivy/run_cm4.sh make rpi2_defconfig
./externals/kivy/run_cm4.sh make menuconfig
./externals/kivy/run_cm4.sh make all
```

For the Intel Stick defconfig:

```shell
./externals/kivy/run_cm4.sh make intelstick_defconfig
./externals/kivy/run_cm4.sh make all
```

To save a modified configuration:

```shell
./externals/kivy/run_cm4.sh make BR2_DEFCONFIG=/buildroot_externals/kivy/configs/mycustom_defconfig savedefconfig
```


# Use of the images produced

- SSH access is enabled for user `root` with password `1`.
- There is a folder `kivyapp` with a simple `hello world` test.


# About the Kivy Package for Buildroot

Details about the purpose and status of this `Kivy Package` can be found
[at package/python-kivy/][package_python_kivy].


# Extra work with the Raspberry Pi2

*⚠️ This is still work in progress ⚠️*

The next content has been based on
[this great post that shows how to build Kivy running on a RP2][evgueni_post]
by [evgueni][evgueni].

**myrpi2_defconfig** — basic image:

```shell
./externals/kivy/run_cm4.sh make myrpi2_defconfig
./externals/kivy/run_cm4.sh make
```

**myrpi2_splash_kivy_defconfig**:

```shell
./externals/kivy/run_cm4.sh make myrpi2_splash_kivy_defconfig
./externals/kivy/run_cm4.sh make
```

**myrpi2_kivy_rofs_defconfig**:

```shell
./externals/kivy/run_cm4.sh make myrpi2_kivy_rofs_defconfig
./externals/kivy/run_cm4.sh make
```


# License

This software is licensed under MIT License.

&copy; 2022 Mauricio Vidal.

[docker_buildroot]: https://github.com/vidalastudillo/docker-buildroot
[br2_external]: https://buildroot.org/downloads/manual/manual.html#outside-br-custom
[DOC_BR2_EXTERNAL]: https://buildroot.org/downloads/manual/manual.html#customize-dir-structure
[evgueni]: https://forums.raspberrypi.com/memberlist.php?mode=viewprofile&u=208985
[evgueni_post]: https://forums.raspberrypi.com/viewtopic.php?t=307052
[package_python_kivy]: /package/python-kivy/
