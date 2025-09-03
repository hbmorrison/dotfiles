#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Default identity.

NAME="Hannah Morrison"
DEFAULT_EMAIL="139557138+hbmorrison@users.noreply.github.com"

# Check if an email address has been provided as an argument.

if [ -n ${1:+z} ]
then

  # If it has, overwrite any existing email address.

  git config --global user.name "${NAME}"
  git config --global user.email "${1}"

else

  # Otherwise, set the default email address if one has not been set already.

  CURRENT_EMAIL=$(git config --global user.email)

  if [ -z ${CURRENT_EMAIL:+z} ]
  then
    git config --global user.name "${NAME}"
    git config --global user.email "${DEFAULT_EMAIL}"
  fi

fi
