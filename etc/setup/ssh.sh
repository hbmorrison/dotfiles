#!/bin/bash

# SSH configuration.

USER_SSH_DIR="${HOME}/.ssh"
SSH_CONFIG_DIR="${ETC_DIR}/ssh"
SSH_CONFIG="${SSH_CONFIG_DIR}/ssh_config_${1,,}"
[ -f "${SSH_CONFIG}" ] || SSH_CONFIG="${SSH_CONFIG_DIR}/ssh_config_default"

# Copy the SSH config file from this repo.

notice "copying ssh config file"
cp -f "${BASE_DIR}/ssh/config" "${HOME}/.ssh/config" &>/dev/null && pass || fail

# Copy additional SSH configuration.

notice "adding ${SSH_CONFIG/*_} ssh configuration"
[ -f "${SSH_CONFIG}" ] || fatal "${SSH_CONFIG/$BASE_DIR\/} missing"
cat "${SSH_CONFIG}" >> "${HOME}/.ssh/config" 2>/dev/null && pass || fail

# Additional ssh config for WSL.

case $OS in
  wsl)

    # Make sure the SSH config is available in the roaming profile.

    notice "copying ssh config files to Windows user profile"
    WSL_SSH_DIR="//wsl.localhost/${WSL_DISTRO_NAME}/${HOME/#\/}/.ssh"
    powershell.exe -Command "cp ${WSL_SSH_DIR}/config ~/.ssh" && pass || fail

    # Disable SSH support in gpg-agent.

    notice "disabling ssh support in gpg-agent"
    sed -i -e "/^\s*enable-ssh-support/s/^/#/" ${HOME}/.gnupg/gpg-agent.conf &>/dev/null \
     && gpg-connect-agent reloadagent /bye \
     && pass || fail
esac
