#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

source /etc/os-release

KEYRING_URL="https://pkgs.tailscale.com/stable/${ID}/${VERSION_CODENAME}.noarmor.gpg"
KEYRING_FILE="tailscale-archive-keyring.gpg"
APT_SOURCE_URL="https://pkgs.tailscale.com/stable/${ID} ${VERSION_CODENAME} main"
APT_SOURCE_FILE="tailscale.list"

DEPENDENCIES="gnupg"
PACKAGES="tailscale tailscale-archive-keyring"

BINARY="/usr/sbin/tailscaled"
SERVICE="tailscaled"

# Install.

source "${BASE_DIR}/bin/install.sh"
