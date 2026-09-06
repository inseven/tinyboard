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

ROOT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"
WEBSITE_DIRECTORY="$ROOT_DIRECTORY/docs"
WEBSITE_DATA_DIRECTORY="$WEBSITE_DIRECTORY/_data"
RELEASES_PATH="$WEBSITE_DATA_DIRECTORY/releases.json"


# Process the command line arguments.
POSITIONAL=()
SERVE=false
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -s|--serve)
        SERVE=true
        shift
        ;;
        *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

# Update the release notes.
mkdir -p "$WEBSITE_DATA_DIRECTORY"
build-tools \
    github-releases inseven tinyboard \
    --synthesize-manifests "$SCRIPTS_DIRECTORY/release-manifest-definition.json" > "$RELEASES_PATH"

# Install the Jekyll dependencies.
cd "$WEBSITE_DIRECTORY"
bundle install

# Get the latest release URL.
if ! DOWNLOAD_URL=$(build-tools latest-github-release inseven tinyboard "TinyBoard-*.zip"); then
    echo >&2 failed
    exit 1
fi
# Belt-and-braces check that we managed to get the download URL.
if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "Failed to get release download URL."
    exit 1
fi
export DOWNLOAD_URL

# Determine the version.
VERSION_NUMBER=`changes version`
export VERSION_NUMBER

# Build the website.
cd "$WEBSITE_DIRECTORY"
if $SERVE ; then
    bundle exec jekyll serve --watch
else
    bundle exec jekyll build
fi
