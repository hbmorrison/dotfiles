#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

source /etc/os-release

KEYRING_URL="https://download.docker.com/linux/${ID}/gpg"
KEYRING_FILE="docker-archive-keyring.gpg"
APT_SOURCE_URL="https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable"
APT_SOURCE_FILE="docker.list"

DEPENDENCIES="apt-transport-https ca-certificates curl gnupg-agent \
  software-properties-common"
PACKAGES="docker-ce docker-ce-cli docker-compose-plugin containerd.io"

BINARY="/usr/bin/docker"
SERVICE="docker"
ADDITIONAL_GROUP="docker"

# Install.

source "${BASE_DIR}/bin/install.sh"
