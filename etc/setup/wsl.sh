#!/bin/bash

# Get Windows environment variables.

WIN_USERPROFILE=$(powershell.exe '$Env:USERPROFILE' | tr -d '\r')
USERPROFILE=$(wslpath -u "${WIN_USERPROFILE}")

# Make sure sudo has valid credentials.

setup_needs_sudo

# Check that WSL is configured correctly.

notice "checking whether WSL is configured correctly"
if ! diff "${ETC_DIR}/wsl/wsl.conf" /etc/wsl.conf &>/dev/null
then
  $SUDO cp -f "${ETC_DIR}/wsl/wsl.conf" /etc/wsl.conf
  RESTART_WSL=1
fi
if ! diff $ETC_DIR/wsl/wslconfig "${USERPROFILE}/.wslconfig" &>/dev/null
then
  cp -f $ETC_DIR/wsl/wslconfig "${USERPROFILE}/.wslconfig"
  RESTART_WSL=1
fi
if [ -z ${RESTART_WSL:+z} ]
then
  yes
else
  no
  echo
  echo " 1. Hit Enter to restart WSL"
  echo " 2. Accept the UAC prompt for Powershell"
  echo " 3. Exit and re-open the Terminal app"
  echo " 4. Re-run 'setup ${SCRIPT}'"
  echo
  read -s
  echo "Restarting..."
  powershell.exe Start-Process -Verb runas -Wait powershell -ArgumentList "\"wsl --shutdown\""
fi

# Fix the WSL2 / Debian clock issue.

if [ ! -x /usr/sbin/hwclock ]
then
  notice "installing hwclock"
  $SUDO apt update -y &>/dev/null \
   && $SUDO apt install -y --no-install-recommends util-linux-extra &>/dev/null \
   && pass || fail
fi

notice "setting system clock from the hardware clock"
$SUDO hwclock -s &>/dev/null && pass || fail

# Install and configure required packages.

setup debian/packages
setup wsl/op
setup wsl/gpg

# Create symlinks to common Windows directories.

setup wsl/symlinks

# Customise the shell environment.

setup shell
