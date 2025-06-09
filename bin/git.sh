#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Set the email address.

EMAIL_ADDRESS="139557138+hbmorrison@users.noreply.github.com"

if [ "${1}" != "" ]
then
  EMAIL_ADDRESS="${1}"
fi

# Set my git identity.

git config --global user.email "${EMAIL_ADDRESS}"
git config --global user.name "Hannah Morrison"
