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

# Install docker.

source "${BASE_DIR}/bin/install.sh"

# Start docker service.

if ! docker info &>/dev/null
then
  $SUDO systemctl start docker
  $SUDO systemctl enable docker
fi

# Check that the current user has permission to interact with docker.

if ! groups "${USER:-$USERNAME}" | grep " docker" &>/dev/null
then
  echo -n "Adding user ${USER:-$USERNAME} to docker group... "
  $SUDO usermod -aG docker "${USER:-$USERNAME}"
  echo "Done"
fi
