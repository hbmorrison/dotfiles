#!/bin/bash

# Get the name of the pipx environment file to run.

INSTALL_ENV=$1
shift

# Print a usage message listing all available pipx installs if the install
# environment file does not exist.

ENV_FILE="${ETC_DIR}/pipx/${INSTALL_ENV}.env"
if [ ! -f $ENV_FILE ]
then
  AVAILABLE_ENVS="("
  for FILE in $ETC_DIR/pipx/*.env
  do
    NAME=$(basename -s .env $FILE | sed 's/^pipx_//')
    AVAILABLE_ENVS+="${NAME}|"
  done
  usage "${AVAILABLE_ENVS/%|/)}"
fi

# Source the environment file.

source ${ENV_FILE} "$@"

# Check that the required variables are set.

[ -z "${PACKAGES}" ] && fatal "no PACKAGES set"

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Install dependencies.

if [ ! -z ${DEPENDENCIES:+z} ]
then
  notice "updating package lists"
  $SUDO apt update -y &>/dev/null && pass || fatal
  notice "installing dependencies"
  $SUDO apt install --no-install-recommends -y $DEPENDENCIES \
   &>/dev/null && pass || fatal
fi

# Install.

for PACKAGE in $PACKAGES
do
  if pipx list --short | grep "^${PACKAGE} " &>/dev/null
  then
    notice "upgrading pipx package ${PACKAGE}"
    pipx upgrade $PACKAGE &>/dev/null && pass || fatal
  else
    notice "installing pipx package ${PACKAGE}"
    pipx install $PACKAGE &>/dev/null && pass || fatal
  fi
done
