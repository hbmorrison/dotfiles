#!/bin/bash

# Configuration.

ONEPASS_SSH_DIR="${APPDATA_LOCAL}/1Password/config/ssh"
CONFIG_DIR="${ETC_DIR}/git"

# Get the name of the profile being set up.

notice "setting profile"
PROFILE="${1:-${SETUP_PROFILE}}"
[ ! -z ${PROFILE:+z} ] && pass || fatal "no profile specified and no SETUP_PROFILE defined"

# Gitconfig.

notice "copying standard git config"
cp -f "${BASE_DIR}/gitconfig" "${HOME}/.gitconfig" \
 &>/dev/null && pass || fail

GIT_CONFIG="${CONFIG_DIR}/git_config_${1}"
[ -f "${GIT_CONFIG}" ] || GIT_CONFIG="${CONFIG_DIR}/git_config_${PROFILE}"

NAME=$(basename ${GIT_CONFIG//_//\/})
notice "adding ${NAME} git config"
[ -f "${GIT_CONFIG}" ] || fatal "${GIT_CONFIG/$BASE_DIR\/} missing"
cat "${GIT_CONFIG}" >> "${HOME}/.gitconfig" 2>/dev/null \
 && pass || fail
