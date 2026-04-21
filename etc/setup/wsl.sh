#!/bin/bash

# Make sure sudo has valid credentials.

setup_needs_sudo

# Check that WSL is configured correctly.

notice "checking whether WSL is configured correctly"
if ! diff "${ETC_DIR}/wsl/wsl.conf" /etc/wsl.conf &>/dev/null
then
  $SUDO cp -f "${ETC_DIR}/wsl/wsl.conf" /etc/wsl.conf
  RESTART_WSL=1
fi
if ! diff $ETC_DIR/wsl/wslconfig "${USER_PROFILE_DIR}/.wslconfig" &>/dev/null
then
  cp -f $ETC_DIR/wsl/wslconfig "${USER_PROFILE_DIR}/.wslconfig"
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

# Install required packages.

setup packages
setup op
setup gpg

# Customise the shell environment.

setup shell
setup symlinks
setup git wsl
setup ssh wsl
setup vim wsl
