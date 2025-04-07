#!/bin/bash

# Locate the base directory of the repository.

SCRIPT=$(readlink -f $0)
BASE_DIR=$(dirname $SCRIPT)

# Configuration.

QMK_DEPENDENCIES="dfu-programmer g++ gcc gcc-arm-none-eabi make python3 pipx"

# Work out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  MSYS*|MINGW64*)            SHELL_ENVIRONMENT="gitbash" ;;
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos" ;;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl" ;;
  *Ubuntu*)                  SHELL_ENVIRONMENT="debian" ;;
  *Red\ Hat*)                SHELL_ENVIRONMENT="redhat" ;;
esac

# Install dependencies.

sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get install --no-install-recommends -y $QMK_DEPENDENCIES

# Install QMK.

echo -n "Checking if QMK is installed ... "
if [ -r "${HOME}/.local/bin/qmk" ]
then
  echo "yes"
else
  echo "no"
  echo "Installing QMK"
  pipx install qmk 2> /dev/null
fi
