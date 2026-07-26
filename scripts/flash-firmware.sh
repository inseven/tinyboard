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

SCRIPTS_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPTS_DIRECTORY/environment.sh"

# Process the command line arguments.
PORT=""
PACKAGE=""
while [[ $# -gt 0 ]]
do
    case "$1" in
        -p|--port)
        shift
        PORT="${1:-}"
        shift || true
        ;;
        *)
        PACKAGE="$1"
        shift
        ;;
    esac
done

# Check the arguments.
if [ -z "$PACKAGE" ] || [ -z "$PORT" ] ; then
    echo "Usage: $(basename "$0") --port <port> <firmware-package>"
    echo
    echo "Available serial ports:"
    python -m serial.tools.list_ports || true
    exit 1
fi

# Flash the firmware onto the board. adafruit-nrfutil exits zero even when it
# fails, so confirm it reported success.
FLASH_LOG="$(mktemp)"
trap 'rm -f "$FLASH_LOG"' EXIT
adafruit-nrfutil dfu serial \
    --package "$PACKAGE" \
    --port "$PORT" \
    --baudrate 115200 \
    --singlebank \
    --touch 1200 2>&1 | tee "$FLASH_LOG"
grep -q "Device programmed." "$FLASH_LOG"
