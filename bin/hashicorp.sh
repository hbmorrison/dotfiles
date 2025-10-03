#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

HASHICORP_APPS="packer vagrant"
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

# Install vagrant.

case $SHELL_ENVIRONMENT in
  chromeos|wsl|debian|ubuntu)
    source /etc/os-release
    if [ ! -f /etc/apt/keyrings/hashicorp-archive-keyring.gpg ]
    then
      curl -fsSL "https://apt.releases.hashicorp.com/gpg" \
        | $SUDO gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main" > $TMP_SOURCE_LIST
    diff $TMP_SOURCE_LIST /etc/apt/sources.list.d/hashicorp.list &>/dev/null;
    if [ $? -ne 0 ]
    then
      cat $TMP_SOURCE_LIST | $SUDO tee /etc/apt/sources.list.d/hashicorp.list
      $SUDO apt update
    fi
    for app in $HASHICORP_APPS
    do
      if [ ! -f "/usr/bin/${app}" ]
      then
        $SUDO apt install --no-install-recommends -y $app
      fi
    done
    ;;
esac
