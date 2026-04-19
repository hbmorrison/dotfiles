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
