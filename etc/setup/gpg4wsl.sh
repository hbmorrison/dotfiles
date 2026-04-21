#!/bin/bash

# Prerequisite packages.

PACKAGES="gpg gpg-agent socat"

# Systemd units for integrating with gpg4win.

SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
EXISTING_SYSTEMD_SOCKETS=(
  "keyboxd.socket"
  "ssh-agent.socket"
  "ssh-agent-browser.socket"
  "ssh-agent-extra.socket"
  "ssh-agent-ssh.socket"
)
SYSTEMD_SOCKETS=(
  "gpg-agent-relay.socket"
  "gpg-agent-extra-relay.socket"
  "gpg-agent-ssh-relay.socket"
  "keyboxd-relay.socket"
  "openssh-ssh-agent.socket"
  "scdaemon-relay.socket"
)
SYSTEMD_SERVICES=(
  "gpg-agent-relay@.service"
  "gpg-agent-extra-relay@.service"
  "gpg-agent-ssh-relay@.service"
  "keyboxd-relay@.service"
  "openssh-ssh-agent@.service"
  "scdaemon-relay@.service"
)
SYSTEMD_LAUNCH_SERVICES=(
  "gpg-agent-launch.service"
  "keyboxd-launch.service"
)

# Location of Gpg4win binaries and config.

GNUPG_DIR="${APPDATA_ROAMING_DIR}/gnupg"
GNUPG_BIN_DIR="/mnt/c/Program Files/GnuPG/bin"

# Public keys to import.

TRUSTED_GPG_PUBLIC_KEYS=(
  "4775913995D1E4B179DFA97A01033E1BAB44EAB5"
)

# Winget packages to install.

WINGET_PACKAGES_DIR="${APPDATA_LOCAL_DIR}/Microsoft/WinGet/Packages"
WINGET_INSTALL_ARGS="--silent --accept-package-agreements --accept-source-agreements"
WINGET_PACKAGES=(
  "AgileBits.1Password.CLI"
  "albertony.npiperelay"
  "GnuPG.Gpg4win"
  "Yubico.YubikeyManager"
  "Yubico.YubiKeyManagerCLI"
)

# Check that the Windows user profile directory is correct.

notice "checking whether user profile directory is accessible"
[ -d "${USER_PROFILE_DIR}" ] && yes || fatal "could not find ${USER_PROFILE_DIR}"

# Make sure sudo has valid credentials.

setup_needs_sudo

# Update and install required packages.

notice "installing required packages"
$SUDO apt update -y &>/dev/null \
 && $SUDO apt install -y --no-install-recommends $PACKAGES &>/dev/null \
 && pass || fail

# Run gpg to create the .gnupg directory structure.

notice "creating .gnupg directory structure"
/usr/bin/gpg --list-keys &>/dev/null \
 && pass || fatal "could not run gpg to create .gnupg"

# Import trusted public keys.

notice "importing trusted public keys"
for KEY in ${TRUSTED_GPG_PUBLIC_KEYS[@]}
do
  if [ -f "${ETC_DIR}/gpg/${KEY}.asc" ]
  then
    /usr/bin/gpg --import "${ETC_DIR}/gpg/${KEY}.asc" &>/dev/null \
     || fatal "could not import ${KEY}"
    echo "${KEY}:6:" | /usr/bin/gpg --import-ownertrust &>/dev/null \
     || fatal "could not trust ${KEY}"
    "${GNUPG_BIN_DIR}/gpg.exe" --import "${ETC_DIR}/gpg/${KEY}.asc" &>/dev/null \
     || fatal "could not import ${KEY} into gpg4win"
    echo "${KEY}:6:" | "${GNUPG_BIN_DIR}/gpg.exe" --import-ownertrust &> /dev/null \
     || fatal "gpg4win could not trust ${KEY}"
  else
    fatal "Public key ${KEY} does not exist"
  fi
done
pass

# Shut down the local gpg-agent which will have started in the background.

notice "shutting down local gpg-agent"
/usr/bin/gpgconf --kill gpg-agent &>/dev/null \
 && pass || fatal "could not shut down gpg-agent"

# Mask existing ssh-agent socket and service.

notice "masking existing gpg and ssh systemd units"
for UNIT in "${EXISTING_SYSTEMD_SOCKETS[@]}"
do
  systemctl --user mask ${UNIT} &>/dev/null \
   || fatal "could not mask ${UNIT}"
done
pass

# Remove any leftover unix sockets.

notice "removing leftover unix sockets"
rm -f "${XDG_RUNTIME_DIR}/gnupg/S."* &>/dev/null \
 && pass || fatal "could not clear old unix sockets"

# Install the required winget packages.

for PACKAGE in "${WINGET_PACKAGES[@]}"
do
  notice "checking whether ${PACKAGE,,} is installed"
  if winget.exe list --exact --id "${PACKAGE}" &>/dev/null
  then
    yes
  else
    no
    notice "installing ${PACKAGE,,}"
    winget.exe install ${WINGET_INSTALL_ARGS} --id "${PACKAGE}" \
     &>/dev/null && pass || fail
  fi
done

# Configure Gpg4Win.

notice "copying gpg4win config files"
[ -d "${GNUPG_DIR}" ] || mkdir "${GNUPG_DIR}" &>/dev/null \
 || fatal "could not create ${GNUPG_DIR}"
cp -f "${BASE_DIR}/gnupg/gpg.conf" "${GNUPG_DIR}/${CONFIG_FILE}" &>/dev/null \
 || fatal "could not copy gpg.conf to ${GNUPG_DIR}"
cp -f "${ETC_DIR}/wsl/gpg-agent.conf" "${GNUPG_DIR}/${CONFIG_FILE}" &>/dev/null \
 || fatal "could not copy gpg-agent.conf to ${GNUPG_DIR}"
pass
notice "restarting gpg4win gpg-agent"
"${GNUPG_BIN_DIR}/gpg-connect-agent.exe" killagent /bye &>/dev/null \
 && "${GNUPG_BIN_DIR}/gpg-connect-agent.exe" /bye &>/dev/null \
 && pass || fail
notice "reloading gpg4win scdaemon"
"${GNUPG_BIN_DIR}/gpgconf.exe" --reload scdaemon &>/dev/null && pass || fail

# Enable user systemd units.

notice "installing gpg and ssh relay systemd units"
[ -d "${SYSTEMD_USER_DIR}" ] || mkdir -p "${SYSTEMD_USER_DIR}" &>/dev/null \
 || fatal "could not create ${SYSTEMD_USER_DIR}"
for UNIT in "${SYSTEMD_SOCKETS[@]}" "${SYSTEMD_SERVICES[@]}" "${SYSTEMD_LAUNCH_SERVICES[@]}"
do
  cp -f "${ETC_DIR}/wsl/${UNIT}" "${SYSTEMD_USER_DIR}" &> /dev/null \
   || fatal "could not copy ${UNIT}"
done
systemctl --user daemon-reload &>/dev/null \
 || fatal "could not reload systemd"
for UNIT in "${SYSTEMD_SOCKETS[@]}" "${SYSTEMD_LAUNCH_SERVICES[@]}"
do
  systemctl --user enable --now $UNIT &>/dev/null \
   || fatal "could not enable ${UNIT}"
done
pass
