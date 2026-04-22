#!/bin/bash

# Configuration.

WINGET_INSTALL_ARGS="--silent --accept-package-agreements --accept-source-agreements"

# Get Windows environment variables.

WIN_APPDATA=$(powershell.exe '$Env:APPDATA' | tr -d '\r')
WIN_LOCALAPPDATA=$(powershell.exe '$Env:LOCALAPPDATA' | tr -d '\r')
WIN_USERPROFILE=$(powershell.exe '$Env:USERPROFILE' | tr -d '\r')
APPDATA=$(wslpath -u "${WIN_APPDATA}")
LOCALAPPDATA=$(wslpath -u "${WIN_LOCALAPPDATA}")
USERPROFILE=$(wslpath -u "${WIN_USERPROFILE}")

# Windows directories.

WINGET_PACKAGES_DIR="${LOCALAPPDATA}/Microsoft/WinGet/Packages"
GPG_CONFIG_DIR="${APPDATA}/gnupg"
GPG_BIN_DIR="/mnt/c/Program Files/GnuPG/bin"

# WSL directories.

SYSTEMD_DIR="${HOME}/.config/systemd/user"

# Prerequisite packages.

PACKAGES="gpg gpg-agent socat"

# Winget prerequisite packages.

WINGET_PACKAGES=(
  "albertony.npiperelay"
  "GnuPG.Gpg4win"
  "Yubico.YubikeyManager"
  "Yubico.YubiKeyManagerCLI"
)

# Systemd units for integrating with gpg4win.

EXISTING_SYSTEMD_UNITS=(
  "gpg-agent.service"
  "gpg-agent.socket"
  "gpg-agent-browser.socket"
  "gpg-agent-extra.socket"
  "gpg-agent-ssh.socket"
  "keyboxd.socket"
)
SYSTEMD_SOCKETS=(
  "gpg-agent-relay.socket"
  "gpg-agent-extra-relay.socket"
  "gpg-agent-ssh-relay.socket"
  "keyboxd-relay.socket"
  "scdaemon-relay.socket"
)
SYSTEMD_SERVICES=(
  "gpg-agent-relay@.service"
  "gpg-agent-extra-relay@.service"
  "gpg-agent-ssh-relay@.service"
  "keyboxd-relay@.service"
  "scdaemon-relay@.service"
)
SYSTEMD_LAUNCH_SERVICES=(
  "gpg-agent-launch.service"
  "keyboxd-launch.service"
)

# Winget packages that contain executables that will be symlinked.

SYMLINK_WINGET_PACKAGE_DIRS=(
  "albertony.npiperelay"
)

# Additional Windows apps that require symlinks.

SYMLINK_WINDOWS_APPS=(
  "/mnt/c/Program Files/GnuPG/bin/gpg.exe"
  "/mnt/c/Program Files/GnuPG/bin/gpgconf.exe"
  "/mnt/c/Program Files/Yubico/YubiKey Manager CLI/ykman.exe"
  "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
)

# Public keys to import.

GPG_TRUSTED_PUBLIC_KEYS=(
  "4775913995D1E4B179DFA97A01033E1BAB44EAB5"
)

# Check that various directories exist first.

notice "checking whether user profile directory is accessible"
[ -d "${USERPROFILE}" ] && yes || fatal "could not find ${USERPROFILE}"
notice "checking whether systemd user directory exists"
[ -d "${SYSTEMD_DIR}" ] || mkdir -p "${SYSTEMD_DIR}" &>/dev/null \
 && yes || fatal "could not create ${SYSTEMD_DIR}"

# Make sure sudo has valid credentials.

setup_needs_sudo

# Update and install required packages.

notice "installing required packages"
$SUDO apt update -y &>/dev/null \
 && $SUDO apt install -y --no-install-recommends $PACKAGES &>/dev/null \
 && pass || fail

# Shut down the local gpg-agent which may have started in the background.

notice "shutting down local gpg-agent"
/usr/bin/gpgconf --kill gpg-agent &>/dev/null \
 && pass || fatal "could not shut down gpg-agent"

# Mask existing agent sockets and services.

notice "masking existing gpg and ssh systemd units"
for UNIT in "${EXISTING_SYSTEMD_UNITS[@]}"
do
  systemctl --user mask ${UNIT} &>/dev/null \
   || fatal "could not mask ${UNIT}"
done
pass

# Stop any relay sockets that might already be in place.

notice "stopping any existing relay sockets"
for UNIT in "${SYSTEMD_SOCKETS[@]}"
do
  if systemctl --user status $UNIT &>/dev/null
  then
    systemctl --user stop $UNIT &>/dev/null || fatal "could not stop ${UNIT}"
  fi
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

# Create symlinks to the executables.

notice "creating symlinks to executables"
for PACKAGE in "${SYMLINK_WINGET_PACKAGE_DIRS[@]}"
do
  mapfile -t EXECUTABLES < <( ls -1 "${WINGET_PACKAGES_DIR}/${PACKAGE}"*/*.exe 2>/dev/null )
  for EXE in "${EXECUTABLES[@]}"
  do
    EXE_NAME=$(basename "${EXE}" | sed 's/\s\+/_/g')
    SYMLINK_PATH="${LOCAL_BIN}/${EXE_NAME}"
    ln -fs "${EXE}" "${SYMLINK_PATH}" &>/dev/null \
     || fatal "could not symlink ${SYMLINK_PATH}"
  done
done
for EXE in "${SYMLINK_WINDOWS_APPS[@]}"
do
  EXE_NAME=$(basename "${EXE}" | sed 's/\s\+/_/g')
  SYMLINK_PATH="${LOCAL_BIN}/${EXE_NAME}"
  ln -fs "${EXE}" "${SYMLINK_PATH}" &>/dev/null \
   || fatal "could not symlink ${SYMLINK_PATH}"
done
pass

# Configure gpg4Win.

notice "copying gpg4win config files"
[ -d "${GPG_CONFIG_DIR}" ] || mkdir "${GPG_CONFIG_DIR}" &>/dev/null \
 || fatal "could not create ${GPG_CONFIG_DIR}"
cp -f "${BASE_DIR}/gnupg/gpg.conf" "${GPG_CONFIG_DIR}/gpg.conf" &>/dev/null \
 || fatal "could not copy gpg.conf to ${GPG_CONFIG_DIR}"
cp -f "${ETC_DIR}/wsl/gpg-agent.conf" "${GPG_CONFIG_DIR}/gpg-agent.conf" &>/dev/null \
 || fatal "could not copy gpg-agent.conf to ${GPG_CONFIG_DIR}"
pass
notice "restarting gpg4win gpg-agent"
"${GPG_BIN_DIR}/gpg-connect-agent.exe" killagent /bye &>/dev/null \
 && "${GPG_BIN_DIR}/gpg-connect-agent.exe" /bye &>/dev/null \
 && pass || fail
notice "reloading gpg4win scdaemon"
"${GPG_BIN_DIR}/gpgconf.exe" --reload scdaemon &>/dev/null && pass || fail

# Enable user systemd units.

notice "installing gpg and ssh relay systemd units"
for UNIT in "${SYSTEMD_SOCKETS[@]}" "${SYSTEMD_SERVICES[@]}" "${SYSTEMD_LAUNCH_SERVICES[@]}"
do
  cp -f "${ETC_DIR}/wsl/${UNIT}" "${SYSTEMD_DIR}" &> /dev/null \
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

# Run gpg to create the .gnupg directory structure.

notice "creating .gnupg directory structure"
/usr/bin/gpg --list-keys &>/dev/null \
 && pass || fatal "could not run gpg to create .gnupg"

# Import trusted public keys.

notice "importing trusted public keys"
for KEY in ${GPG_TRUSTED_PUBLIC_KEYS[@]}
do
  if [ -f "${ETC_DIR}/gpg/${KEY}.asc" ]
  then
    /usr/bin/gpg --import "${ETC_DIR}/gpg/${KEY}.asc" &>/dev/null \
     || fatal "could not import ${KEY}"
    echo "${KEY}:6:" | /usr/bin/gpg --import-ownertrust &>/dev/null \
     || fatal "could not trust ${KEY}"
    "${GPG_BIN_DIR}/gpg.exe" --import "${ETC_DIR}/gpg/${KEY}.asc" &>/dev/null \
     || fatal "could not import ${KEY} into gpg4win"
    echo "${KEY}:6:" | "${GPG_BIN_DIR}/gpg.exe" --import-ownertrust &> /dev/null \
     || fatal "gpg4win could not trust ${KEY}"
  else
    fatal "Public key ${KEY} does not exist"
  fi
done
pass
