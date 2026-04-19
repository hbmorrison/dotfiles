#!/bin/bash

# Location of Gpg4win binaries and config.

GNUPG_DIR="${APPDATA_ROAMING_DIR}/gnupg"
GNUPG_BIN_DIR="/mnt/c/Program Files/GnuPG/bin"

# Winget packages to install.

WINGET_PACKAGES_DIR="${APPDATA_LOCAL_DIR}/Microsoft/WinGet/Packages"
WINGET_INSTALL_ARGS="--silent --accept-package-agreements --accept-source-agreements"
WINGET_PACKAGES=(
  "AgileBits.1Password.CLI"
  "albertony.npiperelay"
  "GnuPG.Gpg4win"
  "Insecure.nmap"
  "Yubico.YubiKeyManagerCLI"
)

# Directories to be symlinked from home directory.

SYMLINK_PC_DIRS=( "C:/Workspace" )
SYMLINK_PROFILE_DIRS=( "Downloads" "Documents" "AppData" )
SYMLINK_ONEDRIVE_DIRS=( "Archive" "System Documentation" )

# Winget packages whose executables will be symlinked from .local/bin/.

SYMLINK_WINGET_PACKAGE_DIRS=(
  "AgileBits.1Password.CLI"
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
  if winget.exe list --query "${PACKAGE}" &>/dev/null
  then
    yes
  else
    no
    notice "installing ${PACKAGE,,}"
    winget.exe install ${WINGET_INSTALL_ARGS} --id "${PACKAGE}" \
     &>/dev/null && pass || fail
  fi
done

# Create symlinks to the executables installed by winget.

for PACKAGE in "${SYMLINK_WINGET_PACKAGE_DIRS[@]}"
do
  mapfile -t EXECUTABLES < <( ls -1 "${WINGET_PACKAGES_DIR}/${PACKAGE}"*/*.exe 2>/dev/null )
  for EXE in "${EXECUTABLES[@]}"
  do
    EXE_NAME=$(basename -s .exe "${EXE}" | sed 's/\s\+/_/g')
    SYMLINK_PATH="${LOCAL_BIN}/${EXE_NAME,,}"
    notice "creating symlink to ${EXE_NAME} in local bin directory"
    if [ -L "${SYMLINK_PATH}" ]
    then
      rm -f "${SYMLINK_PATH}" &>/dev/null || fatal "could not remove existing symlink ${SYMLINK_PATH}"
    fi
    ln -s "${EXE}" "${SYMLINK_PATH}" &>/dev/null && pass || fail
  done
done

# Add the user profile directories and PC directories together.

declare -a SOURCE_DIRS
for DIR in "${SYMLINK_PC_DIRS[@]}"
do
  notice "checking whether ${DIR} exists"
  [ -d "${DIR/#C:/\/mnt\/c}" ] && SOURCE_DIRS+=( "${DIR/#C:/\/mnt\/c}" ) && yes || no
done
for DIR in "${SYMLINK_PROFILE_DIRS[@]}"
do
  notice "checking whether ${USER_PROFILE_DIR/#\/mnt\/c/C:}/${DIR} exists"
  [ -d "${USER_PROFILE_DIR}/${DIR}" ] && SOURCE_DIRS+=( "${USER_PROFILE_DIR}/${DIR}" ) \
   && yes || no
done

# Add OneDrive directory and specific subdirectories.

notice "checking whether OneDrive is available"
ONEDRIVE_DIR=$(/bin/ls -1d "${USER_PROFILE_DIR}/OneDrive"* 2>/dev/null | tail -1)
if [ -d "${ONEDRIVE_DIR}" ] || no
then
  yes
  SOURCE_DIRS+=( "${ONEDRIVE_DIR}" )
  for DIR in "${SYMLINK_ONEDRIVE_DIRS[@]}"
  do
    DIR_NAME=$(basename "${DIR}" | sed 's/\s\+/_/g')
    notice "checking whether OneDrive ${DIR} directory exists"
    [ -d "${ONEDRIVE_DIR}/${DIR}" ] && SOURCE_DIRS+=( "${ONEDRIVE_DIR}/${DIR}" ) \
     && yes || no
  done
fi

# Create symlinks.

for DIR in "${SOURCE_DIRS[@]}"
do
  DIR_NAME=$(basename "${DIR}" | sed 's/\s\+/_/g')
  SYMLINK_NAME="${DIR_NAME/_-_*}"
  SYMLINK_PATH="${HOME}/${SYMLINK_NAME,,}"
  notice "creating symlink ${SYMLINK_NAME,,} in home directory"
  [ -L "${SYMLINK_PATH}" ] && rm -f "${SYMLINK_PATH}" &>/dev/null
  ln -s "${DIR}" "${SYMLINK_PATH}" &>/dev/null && pass || fail
done

# Configure Gpg4Win.

[ -d "${GNUPG_DIR}" ] || mkdir "${GNUPG_DIR}"
for CONFIG_FILE in gpg-agent.conf
do
  notice "copying gpg4win ${CONFIG_FILE}"
  cp -f "${ETC_DIR}/wsl/${CONFIG_FILE}" "${GNUPG_DIR}/${CONFIG_FILE}" \
   &>/dev/null && pass || fatal "could not copy ${CONFIG_FILE} to ${GNUPG_DIR}"
done
notice "stopping gpg4win gpg-agent"
"${GNUPG_BIN_DIR}/gpg-connect-agent.exe" killagent /bye \
 &>/dev/null && pass || fatal "could not stop gpg-agent"
notice "starting gpg4win gpg-agent"
"${GNUPG_BIN_DIR}/gpg-connect-agent.exe" /bye \
 &>/dev/null && pass || fail "could not start gpg-agent"
notice "reloading gpg4win scdaemon"
"${GNUPG_BIN_DIR}/gpgconf.exe" --reload scdaemon \
 &>/dev/null && pass || fatal "could not reload scdaemon"

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

# Run the debian setup script.

setup debian "$@"
