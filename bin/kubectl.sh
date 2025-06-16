#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)
SCRIPT_NAME=$(basename $THIS_SCRIPT)

# Configuration.

KUBERNETES_VERSION=1.33
TMP_SOURCE_LIST=`mktemp`

# Work out whether to run commands using sudo.

SUDO=sudo

if [ `id -u` -eq 0 ]
then
  SUDO=""
fi

# Work out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl" ;;
  *Debian*)                  SHELL_ENVIRONMENT="debian" ;;
  *Ubuntu*)                  SHELL_ENVIRONMENT="debian" ;;
  *)
    echo "Error: operating system not detected"
    exit 1
esac

# Install Kubernetes CLI.

case $SHELL_ENVIRONMENT in
  wsl|debian)
    if [ ! -r  /etc/apt/trusted.gpg.d/kubernetes-apt-keyring.gpg ]
    then
      curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key" \
        | $SUDO gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes-apt-keyring.gpg
    fi
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /" > $TMP_SOURCE_LIST
    diff $TMP_SOURCE_LIST /etc/apt/sources.list.d/kubernetes.list &>/dev/null;
    if [ $? -ne 0 ]
    then
      cat $TMP_SOURCE_LIST | $SUDO tee /etc/apt/sources.list.d/kubernetes.list
      $SUDO apt update
    fi
    if [ ! -r "/usr/bin/kubectl" ]
    then
      $SUDO apt install -y kubectl
    fi
    ;;
esac
