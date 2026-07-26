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
SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"

LOCAL_TOOLS_PATH="$ROOT_DIRECTORY/.local"
CHANGES_DIRECTORY="$SCRIPTS_DIRECTORY/changes"
BUILD_TOOLS_DIRECTORY="$SCRIPTS_DIRECTORY/build-tools"

# Install the firmware toolchain unless we're only building the macOS components.
INSTALL_FIRMWARE_DEPENDENCIES=true
while [[ $# -gt 0 ]]
do
    case "$1" in
        --skip-firmware-dependencies)
        INSTALL_FIRMWARE_DEPENDENCIES=false
        shift
        ;;
        *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
done

# Install tools defined in `.tool-versions`.
cd "$ROOT_DIRECTORY"
mise install

# Clean up and recreate the local tools directory.
if [ -d "$LOCAL_TOOLS_PATH" ] ; then
    rm -r "$LOCAL_TOOLS_PATH"
fi
mkdir -p "$LOCAL_TOOLS_PATH"

# Set up a Python venv to bootstrap our python dependency on `pipenv`.
python -m venv "$LOCAL_TOOLS_PATH/python"

# Source `environment.sh` to ensure the remainder of our paths are set up correctly.
source "$SCRIPTS_DIRECTORY/environment.sh"

# Install the Python dependencies.
pip install --upgrade pip pipenv wheel certifi
PIPENV_PIPFILE="$CHANGES_DIRECTORY/Pipfile" pipenv install
PIPENV_PIPFILE="$BUILD_TOOLS_DIRECTORY/Pipfile" pipenv install

if $INSTALL_FIRMWARE_DEPENDENCIES ; then

    # Install a pinned arduino-cli.
    mkdir -p "$BIN_DIRECTORY"
    curl -fsSL "https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh" \
        | BINDIR="$BIN_DIRECTORY" sh -s "$ARDUINO_CLI_VERSION"
    arduino-cli version

    # Configure arduino-cli.
    arduino-cli config init --overwrite
    arduino-cli config add board_manager.additional_urls "$ADAFRUIT_BOARD_INDEX_URL"

    # Install the Adafruit nRF52 board support package.
    arduino-cli core update-index
    arduino-cli core install "adafruit:nrf52@$NRF52_CORE_VERSION"

    # Install the library dependencies.
    arduino-cli lib install "Adafruit TinyUSB Library@$TINYUSB_LIBRARY_VERSION"

    # Install adafruit-nrfutil; the board package only ships it for macOS and Windows.
    pip install "adafruit-nrfutil==$NRFUTIL_VERSION"

fi
