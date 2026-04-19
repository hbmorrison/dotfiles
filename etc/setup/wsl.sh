#!/bin/bash

# Configuration.

WINGET_PACKAGES_DIR="${APPDATA_LOCAL_DIR}/Microsoft/WinGet/Packages"
WINGET_PACKAGES=( "AgileBits.1Password.CLI" "albertony.npiperelay" "Insecure.nmap" )
WINGET_INSTALL_ARGS="--silent --accept-package-agreements --accept-source-agreements"
WINGET_EXECUTABLE_DIRS=( "AgileBits.1Password.CLI" "albertony.npiperelay" )
SYMLINK_PC_DIRS=( "C:/Workspace" )
SYMLINK_PROFILE_DIRS=( "Downloads" "Documents" "AppData" )
ONEDRIVE_DIRS=( "Archive" "System Documentation" )

# Check that the Windows user profile directory is correct.

notice "checking whether user profile directory is accessible"
[ -d "${USER_PROFILE_DIR}" ] && yes || fatal "could not find ${USER_PROFILE_DIR}"

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

for PACKAGE in "${WINGET_EXECUTABLE_DIRS[@]}"
do
  for EXE in $(ls -1 "${WINGET_PACKAGES_DIR}/${PACKAGE}"*/*.exe 2>/dev/null)
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

# Add OneDrive and any Onedrive directories.

notice "checking whether OneDrive is available"
ONEDRIVE_DIR=$(/bin/ls -1d "${USER_PROFILE_DIR}/OneDrive"* 2>/dev/null | tail -1)
if [ -d "${ONEDRIVE_DIR}" ] || no
then
  yes
  SOURCE_DIRS+=( "${ONEDRIVE_DIR}" )
  for DIR in "${ONEDRIVE_DIRS[@]}"
  do
    ONEDRIVE_DIR_NAME=$(basename "${DIR}" | sed 's/\s\+/_/g')
    notice "checking whether OneDrive $DIR directory exists"
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

if [ -z "${1:+z}" ]
then
  setup debian work
else
  setup debian "$@"
fi
