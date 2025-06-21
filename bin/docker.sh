#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

DOCKER_DEPENDENCIES="apt-transport-https ca-certificates curl gnupg-agent \
  software-properties-common"
DOCKER_PACKAGES="docker-ce docker-ce-cli docker-compose-plugin containerd.io"
TMP_SOURCE_LIST=`mktemp`

# Work out whether to run commands using sudo.

SUDO=sudo

if [ `id -u` -eq 0 ]
then
  SUDO=""
fi

# Work out which OS is being used.

case $(cat /proc/version 2>/dev/null) in
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos" ;;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl" ;;
  *Debian*)                  SHELL_ENVIRONMENT="debian" ;;
  *Ubuntu*)                  SHELL_ENVIRONMENT="ubuntu" ;;
  *)
    echo "This environment is not supported."
    exit 1
    ;;
esac

# Install dependencies.

$SUDO apt install --no-install-recommends -y $DOCKER_DEPENDENCIES

# Install docker.

case $SHELL_ENVIRONMENT in
  chromeos|wsl|debian|ubuntu)
    source /etc/os-release
    if [ ! -f /etc/apt/trusted.gpg.d/docker-apt-keyring.gpg ]
    then
      curl -fsSL "https://download.docker.com/linux/${ID}/gpg" \
        | $SUDO gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-apt-keyring.gpg
    fi
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/docker-apt-keyring.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" > $TMP_SOURCE_LIST
    diff $TMP_SOURCE_LIST /etc/apt/sources.list.d/docker.list &>/dev/null;
    if [ $? -ne 0 ]
    then
      cat $TMP_SOURCE_LIST | $SUDO tee /etc/apt/sources.list.d/docker.list
      $SUDO apt update
    fi
    if [ ! -f /usr/bin/dockerd ]
    then
      $SUDO apt install --no-install-recommends -y $DOCKER_PACKAGES
    fi
    ;;
esac

# Start docker service.

case $SHELL_ENVIRONMENT in
  chromeos|wsl|debian|ubuntu)
    if ! docker info > /dev/null 2>&1
    then
      $SUDO systemctl start docker
      $SUDO systemctl enable docker
    fi
    ;;
esac

# Check that the current user has permission to interact with docker.

if ! groups "${USER:-$USERNAME}" | grep " docker" > /dev/null 2>&1
then
  echo -n "Adding user ${USER:-$USERNAME} to docker group... "
  $SUDO usermod -aG docker "${USER:-$USERNAME}"
  echo "Done"
fi
