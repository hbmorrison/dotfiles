#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

DEPENDENCIES="jq"
TMP_DAEMON_JSON=$(mktemp)

# Work out whether to run commands using sudo.

SUDO=sudo

if [ `id -u` -eq 0 ]
then
  SUDO=""
fi

# Work out which OS is being used.

case $(cat /proc/version 2>/dev/null) in
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos" ;;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl" ;;
  *Debian*)                  SHELL_ENVIRONMENT="debian" ;;
  *Ubuntu*)                  SHELL_ENVIRONMENT="ubuntu" ;;
  *)
    echo "This environment is not supported."
    exit 1
    ;;
esac

if [ ! -f /usr/bin/dockerd ]
then
  echo "Error: docker not installed"
  exit 1
fi

# Install dependencies.

$SUDO apt install --no-install-recommends -y $DEPENDENCIES

# Turn on experimental features.

cp -f /etc/docker/daemon.json $TMP_DAEMON_JSON 2>/dev/null

if ! length=$(jq length $TMP_DAEMON_JSON 2>/dev/null) || [ -z ${length:+z} ]
then

  # If the config file is missing, empty or contains no JSON settings, just
  # create it with the experimental setting enabled.

  echo '{ "experimental": true }' > $TMP_DAEMON_JSON
else

  # Otherwise make sure that the experimental setting is enabled using jq.

  jq '. + { "experimental": true }' $TMP_DAEMON_JSON | $SUDO tee /etc/docker/daemon.json
fi

# Restart the docker daemon if the config file has been changed.

if ! diff $TMP_DAEMON_JSON /etc/docker/daemon.json &>/dev/null
then
  systemctl restart docker
fi

rm -f $TMP_DAEMON_JSON &>/dev/null
