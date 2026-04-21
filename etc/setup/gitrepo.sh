#!/bin/bash

# Program for awk that trims the second field before printing it.

PROGRAM='{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2);print $2}'

# Get the git config.

GIT_CONFIG_DIR="${ETC_DIR}/git"
GIT_CONFIG="${GIT_CONFIG_DIR}/git_config_${1,,}"
[ -f "${GIT_CONFIG}" ] || GIT_CONFIG="${GIT_CONFIG_DIR}/git_config_default"

# Set the name and email from the git config.

git config user.name "$(awk -F= "/name/ ${PROGRAM}" $GIT_CONFIG)"
git config user.email "$(awk -F= "/email/ ${PROGRAM}" $GIT_CONFIG)"

# Show what the local user name and email are set to now.

git config --local --list | grep '^user\.'
