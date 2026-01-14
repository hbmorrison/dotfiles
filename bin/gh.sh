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
  echo "Installing dependencies... "
  $SUDO apt update -y && $SUDO apt install --no-install-recommends -y $DEPENDENCIES
fi

# Install the keyring.

if [ ! -f $KEYRING ]
then
  echo "Installing keyring... "
  curl -fsSL "${KEYRING_URL}" | $SUDO gpg --dearmor -o "${KEYRING}"
fi

# Install the source list.

echo "${APT_SOURCE_CONTENT}" > $TMP_SOURCE

if ! diff $TMP_SOURCE $APT_SOURCE &>/dev/null
then
  echo "Installing source list... "
  cat $TMP_SOURCE | $SUDO tee $APT_SOURCE
  $SUDO apt update -y
fi

# Install the package.

if [ ! -f $BINARY ]
then
  echo "Installing package... "
  $SUDO apt install --no-install-recommends -y $PACKAGES
fi

# Tidy up.

rm -f $TMP_SOURCE &>/dev/null
