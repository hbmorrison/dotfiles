#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

KEYRING_URL="https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"
KEYRING_FILE="brave-browser-archive-keyring.gpg"

APT_SOURCE_URL="https://brave-browser-apt-release.s3.brave.com stable main"
APT_SOURCE_FILE="brave-browser.list"

DEPENDENCIES=""
PACKAGES="brave-browser"

BINARY="/usr/bin/brave-browser"

# Install.

source "${BASE_DIR}/bin/install.sh"
