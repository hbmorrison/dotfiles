#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

DEPENDENCIES="build-essential clang-format diffutils dos2unix \
 libhidapi-hidraw0 python3 pipx unzip wget zip zstd"

if [ "$(uname -m)" == "aarch64" ]
then
  DEPENDENCIES="$DEPENDENCIES arm-none-eabi-gcc avr-gcc avrdude \
   dfu-programmer dfu-util"
fi

# Work out whether to run commands using sudo.

SUDO=sudo

if [ `id -u` -eq 0 ]
then
  SUDO=""
fi

# Install dependencies.

echo -n "Updating package lists... "
if $SUDO apt update -y &>/dev/null
then
  echo "Done"
else
  echo
  echo "Error: run $SUDO apt update -y"
  exit 1
fi
echo -n "Installing dependencies... "
if $SUDO apt install --no-install-recommends -y $DEPENDENCIES &>/dev/null
then
  echo "Done"
else
  echo
  echo "Error: run $SUDO apt install --no-install-recommends -y $DEPENDENCIES"
  exit 1
fi

# Install QMK.

for PACKAGE in uv qmk
do
  if [ ! -r "${HOME}/.local/bin/${PACKAGE}" ]
  then
    echo -n "Installing ${PACKAGE}... "
    if pipx install $PACKAGE &>/dev/null
    then
      echo "Done"
    else
      echo
      echo "Error: run pipx install $PACKAGE"
      exit 1
    fi
  fi
done
