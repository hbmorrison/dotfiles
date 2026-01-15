#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

KEYRING_URL="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
KEYRING_FILE="githubcli-archive-keyring.gpg"

APT_SOURCE_URL="https://cli.github.com/packages stable main"
APT_SOURCE_FILE="github-cli.list"

DEPENDENCIES=""
PACKAGES="gh"

BINARY="/usr/bin/gh"

# Install github-cli.

source "${BASE_DIR}/bin/install.sh"
