#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Check that the authorized_keys file exists.

SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

if [ ! -d $SSH_DIR ]
then
  mkdir -m 0700 $SSH_DIR
fi

if [ ! -f $AUTHORIZED_KEYS ]
then
  touch $AUTHORIZED_KEYS
fi

# Go through each ssh key and add it to authorized_keys if not present.

while read -r TYPE KEY COMMENT
do
  if ! grep "${KEY}" $AUTHORIZED_KEYS > /dev/null 2>&1
  then
    echo "${COMMENT} added to authorized keys"
    echo "${TYPE} ${KEY} ${COMMENT}" >> $AUTHORIZED_KEYS
  fi
done < "${BASE_DIR}/etc/authorized_keys"
