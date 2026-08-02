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

ROOT_DIRECTORY="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" &> /dev/null && pwd )"
SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"

export LOCAL_TOOLS_PATH="$ROOT_DIRECTORY/.local"

export BIN_DIRECTORY="$ROOT_DIRECTORY/.local/bin"
export PATH=$BIN_DIRECTORY:$PATH

# Keep Python user installs local to the project instead of polluting the host.
export PYTHONUSERBASE="$LOCAL_TOOLS_PATH/python"
mkdir -p "$PYTHONUSERBASE"
export PATH="$PYTHONUSERBASE/bin":$PATH

# Keep pipenv virtualenvs local and predictable.
export WORKON_HOME="$LOCAL_TOOLS_PATH"
export PIPENV_CUSTOM_VENV_NAME="venv"
export PIPENV_VENV_IN_PROJECT=0
export PIPENV_IGNORE_VIRTUALENVS=1
export PIPENV_PIPFILE="$SCRIPTS_DIRECTORY/Pipfile"

# Add the tools to the path.
export PATH="$LOCAL_TOOLS_PATH/venv/bin":$PATH

# Pinned firmware toolchain versions.
ARDUINO_CLI_VERSION="1.5.1"
NRF52_CORE_VERSION="1.7.0"
TINYUSB_LIBRARY_VERSION="3.7.7"
NRFUTIL_VERSION="0.5.3.post16"

FQBN="adafruit:nrf52:mdbt50qrx"
ADAFRUIT_BOARD_INDEX_URL="https://adafruit.github.io/arduino-board-index/package_adafruit_index.json"

FIRMWARE_DIRECTORY="$ROOT_DIRECTORY/firmware"
FIRMWARE_BUILD_DIRECTORY="$ROOT_DIRECTORY/build/firmware"

# Vendored as a submodule; not available via the Arduino Library Manager.
MOUSE_KEYBOARD_LIBRARY_DIRECTORY="$FIRMWARE_DIRECTORY/dependencies/TinyUSB_Mouse_and_Keyboard"

# Keep all arduino-cli state within the project.
export ARDUINO_DIRECTORIES_DATA="$LOCAL_TOOLS_PATH/arduino/data"
export ARDUINO_DIRECTORIES_DOWNLOADS="$LOCAL_TOOLS_PATH/arduino/downloads"
export ARDUINO_DIRECTORIES_USER="$LOCAL_TOOLS_PATH/arduino/user"
export ARDUINO_CONFIG_FILE="$LOCAL_TOOLS_PATH/arduino/arduino-cli.yaml"
