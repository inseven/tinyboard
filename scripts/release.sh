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
ARTIFACTS_DIRECTORY="$ROOT_DIRECTORY/artifacts"
BUILD_DIRECTORY="$ROOT_DIRECTORY/build"

ENV_PATH="$ROOT_DIRECTORY/.env"
RELEASE_SCRIPT_PATH="$SCRIPTS_DIRECTORY/gh-release.sh"

source "$SCRIPTS_DIRECTORY/environment.sh"

# Check that the GitHub command is available on the path.
which gh || (echo "GitHub cli (gh) not available on the path." && exit 1)

# Process the command line arguments.
POSITIONAL=()
RELEASE=${RELEASE:-false}
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -r|--release)
        RELEASE=true
        shift
        ;;
        *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

# Source the .env file if it exists to make local development easier.
if [ -f "$ENV_PATH" ] ; then
    echo "Sourcing .env..."
    source "$ENV_PATH"
fi

# Use the version and build number determined by the CI workflow.
VERSION_NUMBER=${VERSION_NUMBER:-0.0.0}
BUILD_NUMBER=${BUILD_NUMBER:-0}

cd "$ROOT_DIRECTORY"

# Clean up and recreate the output directory.
if [ -d "$BUILD_DIRECTORY" ] ; then
    rm -r "$BUILD_DIRECTORY"
fi
mkdir -p "$BUILD_DIRECTORY"

# List the artifacts collected from the previous stages.
find "$ARTIFACTS_DIRECTORY"

# Copy the artifacts to the build directory using explicit, versioned names.
cd "$BUILD_DIRECTORY"

# macOS.
TINYBOARD_MACOS_NAME="TinyBoard-$VERSION_NUMBER-$BUILD_NUMBER.zip"
TINYBOARD_MACOS_BUILD_ARCHIVE_NAME="build-$VERSION_NUMBER-$BUILD_NUMBER.zip"
cp "$ARTIFACTS_DIRECTORY/tinyboard-macos/$TINYBOARD_MACOS_NAME" "$TINYBOARD_MACOS_NAME"
cp "$ARTIFACTS_DIRECTORY/tinyboard-macos/$TINYBOARD_MACOS_BUILD_ARCHIVE_NAME" "$TINYBOARD_MACOS_BUILD_ARCHIVE_NAME"
cp "$ARTIFACTS_DIRECTORY/tinyboard-macos/appcast.xml" appcast.xml

# Firmware (nRF52 serial DFU package, flashable with scripts/flash-firmware.sh).
TINYBOARD_FIRMWARE_NAME="TinyBoard-Firmware-$VERSION_NUMBER-$BUILD_NUMBER.zip"
cp "$ARTIFACTS_DIRECTORY/tinyboard-firmware/firmware.ino.zip" "$TINYBOARD_FIRMWARE_NAME"

if $RELEASE ; then

    changes \
        release \
        --skip-if-empty \
        --push \
        --exec "$RELEASE_SCRIPT_PATH" \
        "$BUILD_DIRECTORY/$TINYBOARD_MACOS_NAME" \
        "$BUILD_DIRECTORY/$TINYBOARD_MACOS_BUILD_ARCHIVE_NAME" \
        "$BUILD_DIRECTORY/appcast.xml" \
        "$BUILD_DIRECTORY/$TINYBOARD_FIRMWARE_NAME"

fi
