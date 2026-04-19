#!/bin/bash

# Fail if any command in a pipe fails.

set -o pipefail

# Work out the hostname and username for a given title.

get_username_from_title () {
  [ -z ${1:+z} ] && fatal "no title given"
  local title="${1}"
  [ -z "${title/*@*}" ] && echo "${title/@*}" && return
  case "${title}" in
    *github*) ;&
    *gitlab*) echo "git" ;;
    *)        echo "${USER}" ;;
  esac
}

get_fqdn_from_title () {
  [ -z ${1:+z} ] &&  fatal "no title given"
  local title="${1}"
  local host="${title/*@}"
  [ -z ${host/*\.*} ] && echo "${host}" && return
  [ -z ${OP_DOMAIN:+z} ] && fatal "OP_DOMAIN not defined"
  echo "${host}.${OP_DOMAIN}"
}

# SSH configuration.

USER_SSH_DIR="${HOME}/.ssh"
SSH_CONFIG_DIR="${ETC_DIR}/ssh"
SSH_CONFIG="${SSH_CONFIG_DIR}/ssh_config_${1,,}"
[ -f "${SSH_CONFIG}" ] || SSH_CONFIG="${SSH_CONFIG_DIR}/ssh_config_default"

# 1Password configuration.

OP_AGENT_CONFIG_DIR="${APPDATA_LOCAL}/1Password/config/ssh"
OP_CONFIG_DIR="${ETC_DIR}/op"
OP_CONFIG="${OP_CONFIG_DIR}/op_config_${1,,}"
[ -f "${OP_CONFIG}" ] || OP_CONFIG="${OP_CONFIG_DIR}/op_config_default"
BASH_CONFIG="${OP_CONFIG_DIR}/bash_config_${1,,}"
[ -f "${BASH_CONFIG}" ] || BASH_CONFIG="${OP_CONFIG_DIR}/bash_config_default"

# Only proceed if 1Password CLI is available.

notice "checking whether 1Password CLI is available"
op --version &>/dev/null && yes || fatal

# 1Password configuration.

notice "copying ${OP_CONFIG/*_} 1Password agent config"
[ -d "${OP_AGENT_CONFIG_DIR}" ] || mkdir -p "${OP_AGENT_CONFIG_DIR}" \
 || fatal "could not create ${OP_AGENT_CONFIG_DIR}"
[ -f "${OP_CONFIG}" ] || fatal "${OP_CONFIG/$BASE_DIR\/} missing"
cp -f "${OP_CONFIG}" "${OP_AGENT_CONFIG_DIR}/agent.toml" &>/dev/null && pass || fail

# Bash configuration.

notice "sourcing ${BASH_CONFIG/*_} bash config"
[ -f "${BASH_CONFIG}" ] || fatal "${BASH_CONFIG/$BASE_DIR\/} missing"
source "${BASH_CONFIG}" &>/dev/null && pass || fail

# Copy the 1password bashrc file from this repo.

notice "copying bash config file for 1Password"
cp -f "${BASE_DIR}/bashrc_op" "${HOME}/.bashrc_op" &>/dev/null && pass || fail
notice "adding ${BASH_CONFIG/*_} bash configuration for 1Password"
cat "${BASH_CONFIG}" >> "${HOME}/.bashrc_op" 2>/dev/null && pass || fail

# Copy the SSH config file from this repo.

notice "copying ssh config file"
cp -f "${BASE_DIR}/ssh/config" "${HOME}/.ssh/config" &>/dev/null && pass || fail

# Limit the 1Password searches to a specific vault.

OP_OPTS="--categories SSHKEY"
[ -z ${OP_VAULT:+z} ] || OP_OPTS+=" --vault ${OP_VAULT}"

# Get a list of SSH Key item IDs from 1Password CLI.

notice "checking whether there are SSH keys in 1Password"
mapfile -t SSH_KEY_IDS < <(
  op item list $OP_OPTS --format json 2>/dev/null | jq -r '.[] .id' 2>/dev/null
)

# Create a public key on disk for each of them and modify the ssh config.

if [ ${#SSH_KEY_IDS} -gt 0 ] || no
then
  yes
  for ID in "${SSH_KEY_IDS[@]}"
  do

    # Get the title and public key of this item.

    notice "checking whether item ${ID} contains a hostname"
    JSON=$(
     op item get "${ID}" --format json 2>/dev/null \
      | jq ". | {title: .title, key: .fields[] | select(.id==\"public_key\") .value}" \
         2>/dev/null \
     ) || no || continue

    # Extract the title and figure out the username and hostname.

    TITLE=$(echo "${JSON}" | jq -r '.title')

    # Skip the item if the title is not a hostname.

    [ "${TITLE}" = "${TITLE//[ \(\)]/_}" ] && yes || no || continue

    # Extract the username and hostname from the title.

    USERNAME=$(get_username_from_title "${TITLE}")
    FQDN=$(get_fqdn_from_title "${TITLE}")
    SHORT=${FQDN/\.*}

    # Create an entry for the identity in the SSH config.

    notice "adding ${SHORT} to SSH config"
    echo "Host ${SHORT} ${FQDN}"         >> "${USER_SSH_DIR}/config" \
     && echo "  User ${USERNAME}"        >> "${USER_SSH_DIR}/config" \
     && echo "  ProxyCommand none"       >> "${USER_SSH_DIR}/config" \
     && pass || fail
  done
fi

# Copy additional SSH configuration.

notice "adding ${SSH_CONFIG/*_} ssh configuration"
[ -f "${SSH_CONFIG}" ] || fatal "${SSH_CONFIG/$BASE_DIR\/} missing"
cat "${SSH_CONFIG}" >> "${HOME}/.ssh/config" 2>/dev/null && pass || fail
