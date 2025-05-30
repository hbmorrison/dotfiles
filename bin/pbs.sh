#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

PBS_REPO_FILE=/etc/apt/sources.list.d/pbs-client.list
PBS_DEPENDENCIES="gnupg-agent"
PBS_PACKAGES="proxmox-backup-client"

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
case $SHELL_ENVIRONMENT in
  chromeos|wsl|debian|ubuntu)
    $SUDO apt-get update
    $SUDO apt-get install --no-install-recommends -y $PBS_DEPENDENCIES
esac

# Source the OS release variables and work out the repo details.

source /etc/os-release

PBS_REPO_URL="http://download.proxmox.com/${ID}/pbs-client"
PBS_GPG_URL="https://enterprise.proxmox.com/${ID}/proxmox-release-${VERSION_CODENAME}.gpg"
PBS_GPG_KEY="/etc/apt/trusted.gpg.d/proxmox-release-${VERSION_CODENAME}.gpg"

# Install backup client.

case $SHELL_ENVIRONMENT in
  chromeos|wsl|debian|ubuntu)
    if [ ! -f $PBS_GPG_KEY ]
    then
      curl -fsSL "${PBS_GPG_URL}" | $SUDO gpg --dearmor -o $PBS_GPG_KEY
    fi
    if [ ! -f $PBS_REPO_FILE ]
    then
      echo "deb [signed-by=${PBS_GPG_KEY}] ${PBS_REPO_URL} ${VERSION_CODENAME} main" \
        | $SUDO tee $PBS_REPO_FILE > /dev/null
      $SUDO apt-get update
    fi
    if [ ! -f /usr/bin/proxmox-backup-client ]
    then
      $SUDO apt-get install --no-install-recommends -y $PBS_PACKAGES
    fi
    ;;
esac
