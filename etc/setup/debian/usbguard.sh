#!/bin/bash

# Configuration.

PACKAGES="usbguard usbguard-notifier"

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Update and install required packages.

notice "installing required packages for usbguard"
$SUDO apt update -y &>/dev/null \
 && $SUDO apt install -y --no-install-recommends $PACKAGES &>/dev/null \
 && pass || fail
