#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

KUBERNETES_VERSION=1.33

KEYRING_URL="https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key"
KEYRING_FILE="kubernetes-archive-keyring.gpg"

APT_SOURCE_URL="https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /"
APT_SOURCE_FILE="kubernetes.list"

DEPENDENCIES=""
PACKAGES="kubectl"

BINARY="/usr/bin/kubectl"

# Install kubectl.

source "${BASE_DIR}/bin/install.sh"
