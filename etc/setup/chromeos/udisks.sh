#!/bin/bash

# Configuration.

PACKAGES="udisks2 exfat-fuse"

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Update and install required packages.

notice "installing required packages for udisks"
$SUDO apt update -y &>/dev/null \
 && $SUDO apt install -y --no-install-recommends $PACKAGES &>/dev/null \
 && pass || fail

# Configure udisks.

notice "Copying udisks mount options to enable exfat support"
$SUDO cp -f $ETC_DIR/chromeos/mount_options.conf /etc/udisks2/mount_options.conf \
 &>/dev/null && pass || fail
notice "Copying udisks polkit rules"
$SUDO cp -f $ETC_DIR/chromeos/99-udisks-polkit.rules /etc/polkit-1/rules.d/99-udisks.rules \
 &>/dev/null && pass || fail
