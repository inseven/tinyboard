# InputStick

USB keyboard proxy

![Photo of the Raytac MDBT50Q-RX USB dongle](images/nRF52840.jpg)

## Overview

InputStick is a keyboard proxy that lets you control another device with your Mac. The project is based on the [Raytac MDBT50Q-RX](https://www.raytac.com/product/ins.php?index_id=89) and provides custom Arduino-based firmware and a corresponding macOS app. The MDBT50Q-RX plugs into the device you wish to control, and the Mac app forwards whatever you type on your Mac keyboard using Bluetooth.

![Photo of an InputStick plugged into a MiSTer](images/mister.jpg)

<p style="text-align: center">The InputStick is perfect for controlling devices like the MiSTer or Raspberry Pi on-the-go</p>

## Getting One

Right now, you'll have to buy a Raytac MDBT50Q-RX from [Adafruit](https://www.adafruit.com/product/5199), flash it, and build the macOS app yourself. It's best to buy from Adafruit as they sell versions pre-flashed with the TinyUF2 boot loader which makes it easy to flash with the Arduino IDE.

If there's enough demand for pre-flashed devices I'm open to selling some flashed ones at a small markup.

## Development

InputStick follows the version numbering, build and signing conventions for InSeven Limited apps. Further details can be found [here](https://github.com/inseven/build-documentation).

## Licensing

InputStick is licensed under the MIT License (see [LICENSE](https://github.com/inseven/inputstick/blob/main/LICENSE)).