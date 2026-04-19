#!/bin/bash

# Configuration.

GIT_CONFIG_DIR="${ETC_DIR}/git"
GIT_CONFIG="${GIT_CONFIG_DIR}/git_config_${1,,}"
[ -f "${GIT_CONFIG}" ] || GIT_CONFIG="${GIT_CONFIG_DIR}/git_config_default"

# Copy the gitconfig file from this repo.

notice "copying git config file"
cp -f "${BASE_DIR}/gitconfig" "${HOME}/.gitconfig" &>/dev/null && pass || fail

# Copy additional git configuration.

notice "adding ${GIT_CONFIG/*_} git configuration"
[ -f "${GIT_CONFIG}" ] || fatal "${GIT_CONFIG/$BASE_DIR\/} missing"
cat "${GIT_CONFIG}" >> "${HOME}/.gitconfig" 2>/dev/null && pass || fail
