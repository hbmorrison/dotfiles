#!/bin/bash

# Configuration.

APT_ARCH=$(dpkg --print-architecture)

# Get the name of the install environment file to use.

INSTALL_ENV=$1
shift

# Check that the environment file exists.

ENV_FILE="${ETC_DIR}/install/${INSTALL_ENV}.env"
if [ ! -f $ENV_FILE ]
then

  # Print a usage message listing all available install environments.

  AVAILABLE_ENVS="("
  for FILE in $ETC_DIR/install/*.env
  do
    NAME=$(basename -s .env $FILE | sed 's/^install_//')
    AVAILABLE_ENVS+="${NAME}|"
  done
  echo "Usage: setup ${SCRIPT} ${AVAILABLE_ENVS/%|/)}"
  exit 1
fi

# Source the environment file.

source ${ENV_FILE} "$@"

# Check that the required variables are set.

[ -z "${KEYRING_URL}" ]     && fatal "no KEYRING_URL set"
[ -z "${KEYRING_FILE}" ]    && fatal "no KEYRING_FILE set"
[ -z "${APT_SOURCE_URL}" ]  && fatal "no APT_SOURCE_URL set"
[ -z "${APT_SOURCE_FILE}" ] && fatal "no APT_SOURCE_FILE set"
[ -z "${PACKAGES}" ]        && fatal "no PACKAGES set"
[ -z $BINARY ]              && fatal "no BINARY set"

# Work out the locations and content of the keyring and source list.

KEYRING="/etc/apt/keyrings/${KEYRING_FILE}"
APT_SOURCE="/etc/apt/sources.list.d/${APT_SOURCE_FILE}"
APT_SOURCE_CONTENT="deb [arch=${APT_ARCH} signed-by=${KEYRING}] ${APT_SOURCE_URL}"
TMP_SOURCE=$(mktemp)

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Install dependencies.

if [ ! -z ${DEPENDENCIES:+z} ]
then
  updating "package lists"
  $SUDO apt update -y &>/dev/null && pass || fatal
  installing "dependencies"
  $SUDO apt install --no-install-recommends -y $DEPENDENCIES &>/dev/null && pass || fatal
fi

# Install the keyring.

if [ ! -f $KEYRING ]
then
  installing "GPG keyring"
  curl -fsSL "${KEYRING_URL}" | $SUDO gpg --dearmor -o "${KEYRING}" \
   &>/dev/null && pass || fatal
fi

# Install the debsig-verify policy.

if [ ! -z ${DEBSIG_POLICY:+z} ]
then
  DEBSIG_POLICY_DIR="/etc/debsig/policies/${DEBSIG_POLICY}"
  DEBSIG_POLICY="${DEBSIG_POLICY_DIR}/${DEBSIG_POLICY_FILE}"
  DEBSIG_KEYRING_DIR="/usr/share/debsig/keyrings/${DEBSIG_POLICY}"
  DEBSIG_KEYRING="${DEBSIG_KEYRING_DIR}/debsig.gpg"

  # Create the policy and policy keyring directories.

  [ -d "${DEBSIG_POLICY_DIR}" ] || $SUDO mkdir -p "${DEBSIG_POLICY_DIR}"
  [ -d "${DEBSIG_KEYRING_DIR}" ] || $SUDO mkdir -p "${DEBSIG_KEYRING_DIR}"

  # Install the policy and policy keyring.

  installing "debsig policy"
  [ -f "${DEBSIG_POLICY}" ] \
   || curl -fsSL ${DEBSIG_POLICY_URL} | $SUDO tee "${DEBSIG_POLICY}" \
   &>/dev/null && pass || fatal
  installing "debsig policy keyring"
  [ -f "${DEBSIG_KEYRING}" ] \
   || curl -fsSL "${KEYRING_URL}" | $SUDO gpg --dearmor -o "${DEBSIG_KEYRING}" \
   &>/dev/null && pass || fatal
fi

# Install the source list.

echo "${APT_SOURCE_CONTENT}" > $TMP_SOURCE
if ! diff $TMP_SOURCE $APT_SOURCE &>/dev/null
then
  installing "apt source list"
  cat $TMP_SOURCE | $SUDO tee $APT_SOURCE &>/dev/null && pass || fatal
  updating "package lists"
  $SUDO apt update -y &>/dev/null && pass || fatal
fi

# Install the packages.

if [ ! -f $BINARY ]
then
  installing "packages"
  echo $SUDO apt install --no-install-recommends -y $PACKAGES
  $SUDO apt install --no-install-recommends -y $PACKAGES
  exit
  $SUDO apt install --no-install-recommends -y $PACKAGES &>/dev/null || fatal
  [ -f $BINARY ] && pass || fatal "$BINARY not found after install"
fi

# Tidy up.

rm -f $TMP_SOURCE &>/dev/null

# Start service if one is specified.

if [ ! -z ${SERVICE:+z} ]
then
  if ! systemctl status $SERVICE &>/dev/null
  then
    starting "${SERVICE} and enabling at boot"
    $SUDO systemctl enable --now $SERVICE &>/dev/null && pass || fatal
  fi
fi

# If an additional group is specified, add the current user to it.

if [ ! -z ${ADDITIONAL_GROUP:+z} ]
then
  if [ $(id -u) -gt 0 ]
  then
    if ! groups "${USER:-$USERNAME}" | grep " ${ADDITIONAL_GROUP}" &>/dev/null
    then
      adding "user ${USER:-$USERNAME} to ${ADDITIONAL_GROUP} group"
      $SUDO usermod -aG $ADDITIONAL_GROUP "${USER:-$USERNAME}" &>/dev/null && pass || fatal
    fi
  fi
fi
