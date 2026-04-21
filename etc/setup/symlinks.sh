#!/bin/bash

# Directories that will be symlinked.

SYMLINK_PC_DIRS=( "C:/Workspace" )
SYMLINK_PROFILE_DIRS=( "Downloads" "Documents" "AppData" )
SYMLINK_ONEDRIVE_DIRS=( "Archive" "System Documentation" )

# Winget packages that contain executables that will be symlinked.

SYMLINK_WINGET_PACKAGE_DIRS=(
  "AgileBits.1Password.CLI"
)

# Collect all of the Windows directories that will be symlinked.

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

# Create home directory symlinks.

notice "creating symlinks in home directory"
for DIR in "${SYMLINK_DIRS[@]}"
do
  DIR_NAME=$(basename "${DIR}" | sed 's/\s\+/_/g')
  SYMLINK_NAME="${DIR_NAME/_-_*}"
  SYMLINK_PATH="${HOME}/${SYMLINK_NAME,,}"
  ln -fs "${DIR}" "${SYMLINK_PATH}" &>/dev/null \
   || fatal "could not symlink ${SYMLINK_PATH}"
done
pass

# Create symlinks to the executables.

notice "creating symlinks to executables in local bin directory"
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
pass
