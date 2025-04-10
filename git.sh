#!/bin/bash

# Locate the base directory of the repository.

SCRIPT=$(readlink -f $0)
BASE_DIR=$(dirname $SCRIPT)

# Set my git identity.

git config --global user.email "139557138+hbmorrison@users.noreply.github.com"
git config --global user.name "Hannah Morrison"
