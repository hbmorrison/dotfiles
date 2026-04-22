#!/bin/bash

# Get Windows environment variables.

WIN_USERPROFILE=$(powershell.exe '$Env:USERPROFILE' | tr -d '\r')
WIN_ONEDRIVE=$(powershell.exe '$Env:ONEDRIVE' | tr -d '\r')
USERPROFILE=$(wslpath -u "${WIN_USERPROFILE}")
ONEDRIVE=$(wslpath -u "${WIN_ONEDRIVE}")

# Directories that will be symlinked.

SYMLINK_PC_DIRS=( "C:/Workspace" )
SYMLINK_PROFILE_SUBDIRS=( "Downloads" "Documents" "AppData" )
SYMLINK_ONEDRIVE_SUBDIRS=( "Archive" "System Documentation" )

# Collect all of the Windows directories that will be symlinked.

notice "collecting directories to symlink from the home directory"
declare -a SYMLINK_DIRS
for DIR in "${SYMLINK_PC_DIRS[@]}"
do
  [ -d "${DIR/#C:/\/mnt\/c}" ] && SYMLINK_DIRS+=( "${DIR/#C:/\/mnt\/c}" )
done
for DIR in "${SYMLINK_PROFILE_SUBDIRS[@]}"
do
  [ -d "${USERPROFILE}/${DIR}" ] && SYMLINK_DIRS+=( "${USERPROFILE}/${DIR}" )
done
if [ -d "${ONEDRIVE}" ]
then
  SYMLINK_DIRS+=( "${ONEDRIVE}" )
  for DIR in "${SYMLINK_ONEDRIVE_SUBDIRS[@]}"
  do
    DIR_NAME=$(basename "${DIR}" | sed 's/\s\+/_/g')
    [ -d "${ONEDRIVE}/${DIR}" ] && SYMLINK_DIRS+=( "${ONEDRIVE}/${DIR}" )
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
