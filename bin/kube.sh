#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)
SCRIPT_NAME=$(basename $THIS_SCRIPT)

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
    echo -n "Checking if Kubernetes CLI is installed... "
    if [ -r "/usr/bin/kubectl" ]
    then
      echo "yes"
    else
      echo "no"
      echo "Installing Kubernetes CLI"
      if [ ! -r  /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg ]
      then
        curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      fi
      if [ ! -r /etc/apt/sources.list.d/kubernetes.list ]
      then
        echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        sudo apt-get update
      fi
      sudo apt-get install -y kubectl
    fi
    ;;
esac
