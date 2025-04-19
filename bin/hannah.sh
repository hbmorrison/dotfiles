#!/bin/sh

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Check that this script is being run by root.

if [ `id -u` -ne 0 ]
then
  echo "Error: run as root"
  exit 1
fi

# Work out which OS and terminal is being used.

source /etc/os-release 2> /dev/null

case $ID in
  debian)
    apt update
    apt install -y sudo
    ;;
  openwrt)
    opkg update
    opkg install shadow-useradd sudo
    ;;
  *)
    echo "Error: operating system not supported"
    exit 1
esac
