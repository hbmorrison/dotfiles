#!/bin/bash

# Fail if any command in a pipe fails.

set -o pipefail

# Get the name of the profile being set up.

setting "profile"
PROFILE="${1:-${SETUP_PROFILE}}"
[ ! -z ${PROFILE:+z} ] && pass || fatal "no profile specified and no SETUP_PROFILE defined"

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

checking "whether 1Password CLI is available"
op --version &>/dev/null && respond_yes || fatal

# Copy the standard SSH config from this repo to start with.

copying "standard ssh config"
cp -f "${BASE_DIR}/ssh/config" "${HOME}/.ssh/config" &>/dev/null && pass || fail

# 1Password configuration in WSL.

copying "${PROFILE} 1Password agent config"
[ -f "${OP_CONFIG}" ] || fatal "${OP_CONFIG/$BASE_DIR\/} missing"
cp -f "${OP_CONFIG}" "${OP_AGENT_CONFIG_DIR}/agent.toml" &>/dev/null && pass || fail

# Get a list of SSH Key item IDs from 1Password CLI.

getting "list of SSH keys from 1Password CLI"
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

    getting "item details"
    JSON=$(
     op item get $OP_GET_OPTS "${ID}" --format json 2>/dev/null \
     | jq ". | {uh: .title, key: .fields[] | select(.id==\"public_key\") .value}" 2>/dev/null
    ) && pass || fail || continue

    # Extract the title and figure out the username and hostname.

    USERHOST=$(echo "${JSON}" | jq -r '.uh')
    if [ -z ${USERHOST/*@*} ]
    then
      USERNAME="${USERHOST/@*}"
      HOST="${USERHOST/*@}"
    else
      USERNAME="${DEFAULT_USER}"
      HOST="${USERHOST}"
    fi
    if [ -z ${HOST/*\.*} ]
    then
      FQDN="${HOST}"
      SHORT="${HOST/\.*/}"
    else
      FQDN="${HOST}.${DEFAULT_DOMAIN}"
      SHORT="${HOST}"
    fi

    # Create an entry for the identity in the SSH config.

    adding "${SHORT} to SSH config"
    echo "Host ${SHORT} ${FQDN}"                      >> "${USER_SSH_DIR}/config" \
     && echo "  User ${USERNAME}"                         >> "${USER_SSH_DIR}/config" \
     && echo "  IdentityFile ${USER_SSH_DIR}/${FQDN}.pub" >> "${USER_SSH_DIR}/config" \
     && pass || fail

    # Add the host key to known_hosts.

    adding "${FQDN} server keys to known_hosts"
    ssh-keyscan "${FQDN}" >> "${USER_SSH_DIR}/known_hosts" \
     2>/dev/null && pass || fail

    # Finally, extract the public key and create the public key file.

    creating "SSH public key file for ${FQDN}"
    echo $JSON | jq -r '.key' 2>/dev/null | tee "${USER_SSH_DIR}/${FQDN}.pub" &>/dev/null \
     && pass || fail
  done
fi

# Add SSH configuration for the profile to the end.

adding "${PROFILE} profile ssh config"
[ -f "${SSH_CONFIG}" ] || fatal "${SSH_CONFIG/$BASE_DIR\/} missing"
cat "${SSH_CONFIG}" >> "${USER_SSH_DIR}/config" 2>/dev/null && pass || fail
