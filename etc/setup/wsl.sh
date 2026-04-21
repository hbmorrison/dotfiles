#!/bin/bash

# 1Password agent configuration.

OP_CONFIG_DIR="${APPDATA_LOCAL_DIR}/1Password/config/ssh"

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
  echo " 3. Open the Terminal app again"
  echo " 4. Re-run 'setup ${SCRIPT}'"
  echo
  read -s
  echo "Restarting..."
  powershell.exe Start-Process -Verb runas -Wait powershell -ArgumentList "\"wsl --shutdown\""
fi

# Configure 1Password CLI.

notice "copying 1Password agent config"
[ -d "${OP_CONFIG_DIR}" ] || mkdir -p "${OP_CONFIG_DIR}" &>/dev/null \
 || fatal "could not create ${OP_CONFIG_DIR}"
cp -f "${ETC_DIR}/wsl/agent.toml" "${OP_CONFIG_DIR}/agent.toml" &>/dev/null \
 || fatal "could not copy agent.toml to ${OP_CONFIG_DIR}"
pass

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

setup packages wsl

# Set up the shell.

setup shell wsl
setup symlinks4wsl "$@"

# Set up gpg.

setup gpg4wsl "$@"

# Customise tools.

setup git wsl
setup ssh wsl
setup vim wsl
