# Building

## Using clickable

To build and run the app on the desktop run:

    clickable desktop

To build a click package for the device run:

clickable build --all --arch arm64 # or amd64 / armhf

See [clickable documentation](https://clickable-ut.dev/en/latest/) for details.

## Without clickable

Install the build dependencies listed in debian/control.

Then run the following commands from inside the project directory:

    mkdir build
    cd build
    cmake -DCLICK_MODE=OFF ..
    make

It can be installed using:

    make install

## Running the app

### On the desktop

No additional steps are required before running the app on the desktop.

You can pass two switches to run in phone or tablet mode from the desktop:

- `-p` for phone mode
- `-t` for tablet mode

### On a device

Ensure that the device is in developer mode, connect it to your build machine,
then use `clickable install` in order to install it on the device.
