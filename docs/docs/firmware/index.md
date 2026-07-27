---
title: Development
---

# Firmware

## Building

You can build the firmware on the command line or using the Arudino IDE.

- [Command Line](#command-line)
- [Arduino IDE](#arduino-ide)

### Command Line

Using the command line is the easiest way to build the firmware---the build scripts can install a local, self-contained copy of the dependencies and libraries, and support building on both macOS and Linux. This is the mechanism used in CI so builds should match exactly what's shipped.

1. Install the dependencies:

   ```sh
   scripts/install-dependencies.sh
   ```

2. Build:

   ```sh
   scripts/build-firmware.sh
   ```

### Arduino IDE

1. Install the latest [Arduino IDE](https://www.arduino.cc/en/software) (2.0.0 at the time of writing).
2. Add the Adafruit-specific board support index by adding `https://adafruit.github.io/arduino-board-index/package_adafruit_index.json` to the additional boards manager URLs in the Arduino preferences.
3. Install the required board support by opening the Boards Manager (Tools > Board > Boards Manager...) and searching for and installing 'Adafruit nRF52' (version 1.7.0 at the time of writing).
4. Install 'Adafruit TinyUSB Library' from the Library Manager (version 3.7.7 at the time of writing).
5. Install the 'TinyUSB_Mouse_and_Keyboard' library using a symlink:

   ```sh
   git submodule update --init
   ln -s \
       "$(pwd)/firmware/dependencies/TinyUSB_Mouse_and_Keyboard" \
       ~/Documents/Arduino/libraries/
   ```

## Debugging

Run [`xev`](https://www.x.org/releases/X11R7.7/doc/man/man1/xev.1.xhtml) on the remote computer to check what events the TinyBoard dongle is sending.

# Mac App

The Mac app relies on [accessibility permission](https://support.apple.com/en-gb/guide/mac-help/mh43185/mac) to capture keyboard and mouse events. When switching between debug and release apps, it's necessary to manually remove the old app, and re-add the new one.

To test the permission request flow, it's necessary to reset the existing permissions for TinyBoard as follows:

```sh
tccutil reset Accessibility uk.co.jbmorley.tinyboard.apps.appstore
```

> [!NOTE]
>
> You might need to reboot to ensure this has taken.
