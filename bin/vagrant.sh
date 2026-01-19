#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

source /etc/os-release

KEYRING_URL="https://apt.releases.hashicorp.com/gpg"
KEYRING_FILE="hashicorp-archive-keyring.gpg"

APT_SOURCE_URL="https://apt.releases.hashicorp.com ${VERSION_CODENAME} main"
APT_SOURCE_FILE="hashicorp.list"

PACKAGES="vagrant"
BINARY="/usr/bin/vagrant"

# Install.

source "${BASE_DIR}/bin/install.sh"
