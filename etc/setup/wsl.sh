#!/bin/bash

# Systemd units for integrating with gpg4win.

SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
SYSTEMD_LAUNCH_UNITS=(
  "gpg-agent-launch.service"
  "keyboxd-launch.service"
)
SYSTEMD_SOCKETS=(
  "gpg-agent-relay.socket"
  "gpg-agent.extra-relay.socket"
  "gpg-agent.ssh-relay.socket"
  "keyboxd-relay.socket"
  "openssh-ssh-agent.socket"
  "scdaemon-relay.socket"
)

# 1Password agent configuration.

OP_CONFIG_DIR="${APPDATA_LOCAL_DIR}/1Password/config/ssh"

# Location of Gpg4win binaries and config.

GNUPG_DIR="${APPDATA_ROAMING_DIR}/gnupg"
GNUPG_BIN_DIR="/mnt/c/Program Files/GnuPG/bin"

# Public keys to import.

MY_GPG_PUBLIC_KEYS=( "4775913995D1E4B179DFA97A01033E1BAB44EAB5" )

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

# Directories to be symlinked from home directory.

SYMLINK_PC_DIRS=( "C:/Workspace" )
SYMLINK_PROFILE_DIRS=( "Downloads" "Documents" "AppData" )
SYMLINK_ONEDRIVE_DIRS=( "Archive" "System Documentation" )

# Winget packages whose executables will be symlinked from the local bin
# directory.

SYMLINK_WINGET_PACKAGE_DIRS=(
  "AgileBits.1Password.CLI"
  "albertony.npiperelay"
)

# Additional apps that require symlinks.

SYMLINK_APPS=(
  "/mnt/c/Program Files/GnuPG/bin/gpg.exe"
  "/mnt/c/Program Files/GnuPG/bin/gpgconf.exe"
  "/mnt/c/Program Files/Yubico/YubiKey Manager CLI/ykman.exe"
)

# Check that the Windows user profile directory is correct.

notice "checking whether user profile directory is accessible"
[ -d "${USER_PROFILE_DIR}" ] && yes || fatal "could not find ${USER_PROFILE_DIR}"

# Check that WSL is configured correctly.

notice "checking whether WSL is configured correctly"
if ! diff "${ETC_DIR}/wsl/wsl.conf" /etc/wsl.conf &>/dev/null
then
  $SUDO cp -f "${ETC_DIR}/wsl/wsl.conf" /etc/wsl.conf
  RESTART_WSL=1
fi
if ! diff $ETC_DIR/wsl/wslconfig "${USER_PROFILE_DIR}/.wslconfig" &>/dev/null
then
  cp -f $ETC_DIR/wsl/wslconfig "${USER_PROFILE_DIR}/.wslconfig"
  RESTART_WSL=1
fi
if [ -z ${RESTART_WSL:+z} ]
then
  yes
else
  no
  echo
  echo " 1. Hit Enter to restart WSL"
  echo " 2. Accept the UAC prompt for Powershell"
  echo " 3. Open the Terminal app again"
  echo " 4. Re-run 'setup ${SCRIPT}'"
  echo
  read -s
  echo "Restarting..."
  powershell.exe Start-Process -Verb runas -Wait powershell -ArgumentList "\"wsl --shutdown\""
fi

# Install the required packages using winget.

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

# Add the user profile directories and PC directories together.

notice "collecting directories to symlink from the home directory"
declare -a SYMLINK_DIRS
for DIR in "${SYMLINK_PC_DIRS[@]}"
do
  [ -d "${DIR/#C:/\/mnt\/c}" ] && SYMLINK_DIRS+=( "${DIR/#C:/\/mnt\/c}" )
done
for DIR in "${SYMLINK_PROFILE_DIRS[@]}"
do
  [ -d "${USER_PROFILE_DIR}/${DIR}" ] && SYMLINK_DIRS+=( "${USER_PROFILE_DIR}/${DIR}" )
done
ONEDRIVE_DIR=$(/bin/ls -1d "${USER_PROFILE_DIR}/OneDrive"* 2>/dev/null | tail -1)
if [ -d "${ONEDRIVE_DIR}" ]
then
  SYMLINK_DIRS+=( "${ONEDRIVE_DIR}" )
  for DIR in "${SYMLINK_ONEDRIVE_DIRS[@]}"
  do
    DIR_NAME=$(basename "${DIR}" | sed 's/\s\+/_/g')
    [ -d "${ONEDRIVE_DIR}/${DIR}" ] && SYMLINK_DIRS+=( "${ONEDRIVE_DIR}/${DIR}" )
  done
fi
pass

# Create symlinks.

notice "creating symlinks in home directory"
for DIR in "${SYMLINK_DIRS[@]}"
do
  DIR_NAME=$(basename "${DIR}" | sed 's/\s\+/_/g')
  SYMLINK_NAME="${DIR_NAME/_-_*}"
  SYMLINK_PATH="${HOME}/${SYMLINK_NAME,,}"
  ln -nfs "${DIR}" "${SYMLINK_PATH}" &>/dev/null \
   fatal "could not symlink ${SYMLINK_PATH}"
done
pass

# Create symlinks to the executables.

notice "creating symlinks to executables"
for PACKAGE in "${SYMLINK_WINGET_PACKAGE_DIRS[@]}"
do
  mapfile -t EXECUTABLES < <( ls -1 "${WINGET_PACKAGES_DIR}/${PACKAGE}"*/*.exe 2>/dev/null )
  for EXE in "${EXECUTABLES[@]}"
  do
    EXE_NAME=$(basename "${EXE}" | sed 's/\s\+/_/g')
    SYMLINK_PATH="${LOCAL_BIN}/${EXE_NAME}"
    ln -nfs "${EXE}" "${SYMLINK_PATH}" &>/dev/null \
     || fatal "could not symlink ${SYMLINK_PATH}"
  done
done
for EXE in "${SYMLINK_APPS[@]}"
do
  EXE_NAME=$(basename "${EXE}" | sed 's/\s\+/_/g')
  SYMLINK_PATH="${LOCAL_BIN}/${EXE_NAME}"
  ln -nfs "${EXE}" "${SYMLINK_PATH}" &>/dev/null \
   || fatal "could not symlink ${SYMLINK_PATH}"
done
pass

# Configure 1Password CLI.

notice "copying 1Password agent config"
[ -d "${OP_CONFIG_DIR}" ] || mkdir -p "${OP_CONFIG_DIR}" &>/dev/null \
 || fatal "could not create ${OP_CONFIG_DIR}"
cp -f "${ETC_DIR}/wsl/agent.toml" "${OP_CONFIG_DIR}/agent.toml" &>/dev/null \
 || fatal "could not copy agent.toml to ${OP_CONFIG_DIR}"
pass

# Configure Gpg4Win.

notice "copying gpg4win config files"
[ -d "${GNUPG_DIR}" ] || mkdir "${GNUPG_DIR}" &>/dev/null \
 || fatal "could not create ${GNUPG_DIR}"
for CONFIG_FILE in gpg.conf gpg-agent.conf
do
  cp -f "${ETC_DIR}/wsl/${CONFIG_FILE}" "${GNUPG_DIR}/${CONFIG_FILE}" &>/dev/null \
   || fatal "could not copy ${CONFIG_FILE} to ${GNUPG_DIR}"
done
pass

notice "restarting gpg4win gpg-agent"
"${GNUPG_BIN_DIR}/gpg-connect-agent.exe" killagent /bye &>/dev/null \
 && "${GNUPG_BIN_DIR}/gpg-connect-agent.exe" /bye &>/dev/null \
 && pass || fail
notice "reloading gpg4win scdaemon"
"${GNUPG_BIN_DIR}/gpgconf.exe" --reload scdaemon &>/dev/null && pass || fail

# Mask existing ssh-agent socket and service.

notice "masking existing ssh-agent systemd units"
systemctl --user mask ssh-agent.socket &>/dev/null \
 || fatal "could not mask ssh-agent.socket"
systemctl --user mask ssh-agent.service &>/dev/null \
 || fatal "could not mask ssh-agent.service"
pass

# Enable user systemd units.

notice "installing systemd units into user systemd directory"
[ -d "${SYSTEMD_USER_DIR}" ] || mkdir -p "${SYSTEMD_USER_DIR}" &>/dev/null \
 || fatal "could not create ${SYSTEMD_USER_DIR}"
for UNIT in ${SYSTEMD_LAUNCH_UNITS[@]} ${SYSTEMD_SOCKETS[@]}
do
  cp -f "${ETC_DIR}/wsl/${UNIT}" "${SYSTEMD_USER_DIR}" &> /dev/null \
   || fatal "could not copy ${UNIT}"
done
systemctl --user daemon-reload &>/dev/null \
 || fatal "could not reload systemd"
for UNIT in ${SYSTEMD_LAUNCH_UNITS[@]} ${SYSTEMD_SOCKETS[@]}
do
  systemctl --user enable --now $UNIT &>/dev/null \
   || fatal "could not enable ${UNIT}"
done
pass

# Import public keys.

notice "importing my public keys"
for KEY in ${MY_GPG_PUBLIC_KEYS[@]}
do
  gpg --import "${ETC_DIR}/gpg/${KEY}.asc" &>/dev/null \
   || fatal "could not import ${KEY}"
  gpg.exe --import "${ETC_DIR}/gpg/${KEY}.asc" &>/dev/null \
   || fatal "could not import ${KEY} into gpg4win"
done
pass

notice "trusting my public keys"
for KEY in ${MY_GPG_PUBLIC_KEYS[@]}
do
  echo "${KEY}:6:" | gpg --import-ownertrust &>/dev/null \
   || fatal "could not trust ${KEY}"
  echo "${KEY}:6:" | "${GNUPG_BIN_DIR}/gpg.exe" --import-ownertrust &> /dev/null \
   || fatal "gpg4win could not trust ${KEY}"
done
pass

# Make sure sudo has valid credentials.

setup_needs_sudo

# Fix the WSL2 / Debian clock issue.

if [ ! -x /usr/sbin/hwclock ]
then
  notice "installing hwclock"
  $SUDO apt update -y &>/dev/null \
   && $SUDO apt install -y --no-install-recommends util-linux-extra &>/dev/null \
   && pass || fail
fi

notice "setting system clock from the hardware clock"
$SUDO hwclock -s &>/dev/null && pass || fail

# Install required packages.

setup packages wsl

# Set up the shell.

setup shell wsl

# Customise tools.

setup git wsl
setup ssh wsl
setup vim wsl
