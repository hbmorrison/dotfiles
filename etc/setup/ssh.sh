#!/bin/bash

# Get the name of the profile being set up.

setting "profile"
PROFILE="${1:-${SETUP_PROFILE}}"
[ ! -z ${PROFILE:+z} ] && pass || fatal "no profile specified and no SETUP_PROFILE defined"

# SSH configuration.

USER_SSH_DIR="${HOME}/.ssh"
SSH_CONFIG_DIR="${ETC_DIR}/ssh"
SSH_CONFIG="${SSH_CONFIG_DIR}/ssh_config_${PROFILE,,}"

# Copy the standard SSH config from this repo.

copying "standard ssh config"
cp -f "${BASE_DIR}/ssh/config" "${HOME}/.ssh/config" &>/dev/null && pass || fail

# Add SSH configuration for the profile to the end.

adding "${PROFILE} ssh config"
[ -f "${SSH_CONFIG}" ] || fatal "${SSH_CONFIG/$BASE_DIR\/} missing"
cat "${SSH_CONFIG}" >> "${HOME}/.ssh/config" 2>/dev/null && pass || fail
