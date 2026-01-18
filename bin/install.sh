#!/bin/bash

# Configuration.

if [ -z "${KEYRING_URL}" ]
then
  echo "Error: no KEYRING_URL set"
  exit 1
fi

if [ -z "${KEYRING_FILE}" ]
then
  echo "Error: no KEYRING_FILE set"
  exit 1
fi

if [ -z "${APT_SOURCE_URL}" ]
then
  echo "Error: no APT_SOURCE_URL set"
  exit 1
fi

if [ -z "${APT_SOURCE_FILE}" ]
then
  echo "Error: no APT_SOURCE_FILE set"
  exit 1
fi

if [ -z "${PACKAGES}" ]
then
  echo "Error: no PACKAGES set"
  exit 1
fi

if [ -z $BINARY ]
then
  echo "Error: no BINARY set"
  exit 1
fi

# Work out the locations and content of the keyring and source list.

KEYRING="/etc/apt/keyrings/${KEYRING_FILE}"
APT_SOURCE="/etc/apt/sources.list.d/${APT_SOURCE_FILE}"
APT_ARCH=$(dpkg --print-architecture)
APT_SOURCE_CONTENT="deb [arch=${APT_ARCH} signed-by=${KEYRING}] ${APT_SOURCE_URL}"
TMP_SOURCE=$(mktemp)

# Work out whether to run commands using sudo.

SUDO=sudo

if [ `id -u` -eq 0 ]
then
  SUDO=""
fi

# Install dependencies.

if [ ! -z ${DEPENDENCIES:+z} ]
then
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
fi

# Install the keyring.

if [ ! -f $KEYRING ]
then
  echo -n "Installing keyring... "
  curl -fsSL "${KEYRING_URL}" | $SUDO gpg --dearmor -o "${KEYRING}" &>/dev/null
  echo "Done"
fi

# Install the source list.

echo "${APT_SOURCE_CONTENT}" > $TMP_SOURCE

if ! diff $TMP_SOURCE $APT_SOURCE &>/dev/null
then
  echo -n "Installing source list... "
  cat $TMP_SOURCE | $SUDO tee $APT_SOURCE &>/dev/null
  echo "Done"
  echo -n "Updating package lists... "
  if $SUDO apt update -y &>/dev/null
  then
    echo "Done"
  else
    echo
    echo "Error: run $SUDO apt update -y"
    exit 1
  fi
fi

# Install the packages.

if [ ! -f $BINARY ]
then
  echo -n "Installing packages... "
  if $SUDO apt install --no-install-recommends -y $PACKAGES &>/dev/null
  then
    if [ -f $BINARY ]
    then
      echo "Done"
    else
      echo
      echo "Error: package binary $BINARY not found after install"
      exit 1
    fi
  else
    echo
    echo "Error: run $SUDO apt install --no-install-recommends -y $PACKAGES"
    exit 1
  fi
fi

# Tidy up.

rm -f $TMP_SOURCE &>/dev/null

# Start service if one is specified.

if [ ! -z ${SERVICE:+z} ]
then
  if ! systemctl status $SERVICE &>/dev/null
  then
    echo -n "Starting ${SERVICE} and enabling at boot... "
    $SUDO systemctl start $SERVICE &>/dev/null
    $SUDO systemctl enable $SERVICE &>/dev/null
    echo "Done"
  fi
fi

# If an additional group is specified, add the current user to it.

if [ ! -z ${ADDITIONAL_GROUP:+z} ]
then
  if [ ! -z ${SUDO:+z} ]
  then
    if ! groups "${USER:-$USERNAME}" | grep " ${ADDITIONAL_GROUP}" &>/dev/null
    then
      echo -n "Adding user ${USER:-$USERNAME} to ${ADDITIONAL_GROUP} group... "
      $SUDO usermod -aG $ADDITIONAL_GROUP "${USER:-$USERNAME}" &>/dev/null
      echo "Done"
    fi
  fi
fi
