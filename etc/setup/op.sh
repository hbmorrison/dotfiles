#!/bin/bash

# Fail if any command in a pipe fails.

set -o pipefail

# Work out the hostname and username for a given title.

get_username_from_title () {
  [ -z ${1:+z} ] && fatal "no title given"
  local title="${1}"
  [ -z ${title/*@*} ] && echo "${title/@*}" && return
  case "${title}" in
    *github*) ;&
    *gitlab*) echo "git" && return ;;
    *)        echo "${SETUP_USER:-$USER}" ;;
  esac
}

get_fqdn_from_title () {
  [ -z ${1:+z} ] &&  fatal "no title given"
  local title="${1}"
  local host="${title/*@}"
  [ -z ${host/*\.*} ] && echo "${host}" && return
  [ -z ${SETUP_DOMAIN:+z} ] && fatal "SETUP_DOMAIN not defined"
  echo "${host}.${SETUP_DOMAIN}"
}

# Get the name of the profile to use.

PROFILE=$(get_profile "${1}")

# SSH configuration.

USER_SSH_DIR="${HOME}/.ssh"
SSH_CONFIG_DIR="${ETC_DIR}/ssh"
SSH_CONFIG="${SSH_CONFIG_DIR}/ssh_config_${PROFILE,,}"

# 1Password configuration.

OP_AGENT_CONFIG_DIR="${APPDATA_LOCAL}/1Password/config/ssh"
OP_CONFIG_DIR="${ETC_DIR}/op"
OP_CONFIG="${OP_CONFIG_DIR}/op_config_${PROFILE,,}"
OP_VAULT="${PROFILE,,}"
OP_TAG="authkey"
OP_LIST_OPTS="--vault ${OP_VAULT} --tags ${OP_TAG}"
OP_GET_OPTS="--vault ${OP_VAULT}"

# Only proceed if 1Password CLI is available.

notice "checking whether 1Password CLI is available"
op --version &>/dev/null && pass || fatal

# Copy the standard SSH config from this repo to start with.

notice "copying standard ssh config"
cp -f "${BASE_DIR}/ssh/config" "${HOME}/.ssh/config" &>/dev/null && pass || fail

# 1Password configuration in WSL.

notice "copying ${PROFILE} 1Password agent config"
[ -f "${OP_CONFIG}" ] || fatal "${OP_CONFIG/$BASE_DIR\/} missing"
cp -f "${OP_CONFIG}" "${OP_AGENT_CONFIG_DIR}/agent.toml" &>/dev/null && pass || fail

# Get a list of SSH Key item IDs from 1Password CLI.

notice "getting list of SSH keys from 1Password CLI"
mapfile -t SSH_KEY_IDS < <(
  op item list $OP_LIST_OPTS --format json 2>/dev/null \
   | jq -r '.[] .id' 2>/dev/null
)

# Create a public key on disk for each of them and modify the ssh config.

if [ ${#SSH_KEY_IDS} -gt 0 ] || fail
then
  pass
  for ID in "${SSH_KEY_IDS[@]}"
  do

    # Get the title and public key of this item.

    notice "getting item details"
    JSON=$(
     op item get $OP_GET_OPTS "${ID}" --format json 2>/dev/null \
     | jq ". | {title: .title, key: .fields[] | select(.id==\"public_key\") .value}" 2>/dev/null
    ) && pass || fail || continue

    # Extract the title and figure out the username and hostname.

    TITLE=$(echo "${JSON}" | jq -r '.title')
    USERNAME=$(get_username_from_title "${TITLE}")
    FQDN=$(get_fqdn_from_title "${TITLE}")
    SHORT=${FQDN/\.*}

    # Create an entry for the identity in the SSH config.

    notice "adding ${SHORT} to SSH config"
    echo "Host ${SHORT} ${FQDN}"         >> "${USER_SSH_DIR}/config" \
     && echo "  User ${USERNAME}"        >> "${USER_SSH_DIR}/config" \
     && pass || fail
  done
fi

# Add SSH configuration for the profile to the end.

notice "adding ${PROFILE} profile ssh config"
[ -f "${SSH_CONFIG}" ] || fatal "${SSH_CONFIG/$BASE_DIR\/} missing"
cat "${SSH_CONFIG}" >> "${USER_SSH_DIR}/config" 2>/dev/null && pass || fail
