#!/bin/bash

# Copyright (c) 2022-2026 Jason Morley
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -e
set -o pipefail
set -x
set -u

ROOT_DIRECTORY="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" &> /dev/null && pwd )"

FIRMWARE_DIRECTORY="$ROOT_DIRECTORY/firmware"
BUILD_DIRECTORY="$ROOT_DIRECTORY/build/firmware"
LOCAL_TOOLS_PATH="$ROOT_DIRECTORY/.local"

# Pinned board and toolchain versions.
ARDUINO_CLI_VERSION="1.5.1"
NRF52_CORE_VERSION="1.7.0"
TINYUSB_LIBRARY_VERSION="3.7.7"
NRFUTIL_VERSION="0.5.3.post16"

FQBN="adafruit:nrf52:mdbt50qrx"
ADAFRUIT_BOARD_INDEX_URL="https://adafruit.github.io/arduino-board-index/package_adafruit_index.json"

# Vendored as a submodule; not available via the Arduino Library Manager.
MOUSE_KEYBOARD_LIBRARY_DIRECTORY="$FIRMWARE_DIRECTORY/dependencies/TinyUSB_Mouse_and_Keyboard"

ARDUINO_CLI="$LOCAL_TOOLS_PATH/bin/arduino-cli"

# Keep all arduino-cli state within the project.
export ARDUINO_DIRECTORIES_DATA="$LOCAL_TOOLS_PATH/arduino/data"
export ARDUINO_DIRECTORIES_DOWNLOADS="$LOCAL_TOOLS_PATH/arduino/downloads"
export ARDUINO_DIRECTORIES_USER="$LOCAL_TOOLS_PATH/arduino/user"
export ARDUINO_CONFIG_FILE="$LOCAL_TOOLS_PATH/arduino/arduino-cli.yaml"

# Install a pinned arduino-cli.
mkdir -p "$LOCAL_TOOLS_PATH/bin"
if [ ! -x "$ARDUINO_CLI" ] || ! "$ARDUINO_CLI" version | grep -q "$ARDUINO_CLI_VERSION" ; then
    curl -fsSL "https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh" \
        | BINDIR="$LOCAL_TOOLS_PATH/bin" sh -s "$ARDUINO_CLI_VERSION"
fi
"$ARDUINO_CLI" version

# Configure arduino-cli.
"$ARDUINO_CLI" config init --overwrite
"$ARDUINO_CLI" config add board_manager.additional_urls "$ADAFRUIT_BOARD_INDEX_URL"

# Install the Adafruit nRF52 board support package.
"$ARDUINO_CLI" core update-index
"$ARDUINO_CLI" core install "adafruit:nrf52@$NRF52_CORE_VERSION"

# Install the library dependencies.
"$ARDUINO_CLI" lib install "Adafruit TinyUSB Library@$TINYUSB_LIBRARY_VERSION"

# Install adafruit-nrfutil; the board package only ships it for macOS and Windows.
NRFUTIL_DIRECTORY="$LOCAL_TOOLS_PATH/nrfutil"
if [ ! -x "$NRFUTIL_DIRECTORY/bin/adafruit-nrfutil" ] ; then
    python3 -m venv "$NRFUTIL_DIRECTORY"
    "$NRFUTIL_DIRECTORY/bin/pip" install --upgrade pip
    "$NRFUTIL_DIRECTORY/bin/pip" install "adafruit-nrfutil==$NRFUTIL_VERSION"
fi
export PATH="$NRFUTIL_DIRECTORY/bin:$PATH"

# Build the firmware.
rm -rf "$BUILD_DIRECTORY"
mkdir -p "$BUILD_DIRECTORY"
"$ARDUINO_CLI" compile \
    --fqbn "$FQBN" \
    --output-dir "$BUILD_DIRECTORY" \
    --library "$MOUSE_KEYBOARD_LIBRARY_DIRECTORY" \
    --warnings default \
    "$FIRMWARE_DIRECTORY"
