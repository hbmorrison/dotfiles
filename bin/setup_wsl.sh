#!/bin/bash

# Configuration.

USER_PROFILE="/mnt/c/Users/${USER}"
SYMLINK_PROFILE_DIRS=( "Downloads" "Documents" "Dropbox" "AppData" )
SYMLINK_PC_DIRS=( "C:/Workspace" "C:/ProgramData" )
ONEDRIVE_DIRS=( "Archive" "System Documentation" )

# Check that we have the correct Windows user profile directory.

checking "whether user profile directory exists"
[ -d "${USER_PROFILE}" ] && respond_yes || respond_no "could not find user profile directory"

# Add the user profile directories and PC directories together.

declare -a SOURCE_DIRS
for DIR in "${SYMLINK_PC_DIRS[@]}"
do
  checking "whether ${DIR} exists"
  [ -d "${DIR/#C:/\/mnt\/c}" ] && SOURCE_DIRS+=( "${DIR/#C:/\/mnt\/c}" ) \
   && respond_yes || respond_no
done
for DIR in "${SYMLINK_PROFILE_DIRS[@]}"
do
  checking "whether ${USER_PROFILE/#\/mnt\/c/C:}/${DIR} exists"
  [ -d "${USER_PROFILE}/${DIR}" ] && SOURCE_DIRS+=( "${USER_PROFILE}/${DIR}" ) \
   && respond_yes || respond_no
done

# Add OneDrive and any Onedrive directories.

checking "whether OneDrive is available"
ONEDRIVE_DIR=$(/bin/ls -1d "${USER_PROFILE}/OneDrive"* 2>/dev/null | tail -1)
if [ -d "${ONEDRIVE_DIR}" ] && respond_yes || respond_no
then
  SOURCE_DIRS+=( "${ONEDRIVE_DIR}" )
  for DIR in "${ONEDRIVE_DIRS[@]}"
  do
    ONEDRIVE_DIR_NAME=$(basename "${DIR}" | sed 's/\s\+/_/g')
    checking "whether OneDrive $DIR directory exists"
    [ -d "${ONEDRIVE_DIR}/${DIR}" ] && SOURCE_DIRS+=( "${ONEDRIVE_DIR}/${DIR}" ) \
     && respond_yes || respond_no
  done
fi

# Create symlinks.

for DIR in "${SOURCE_DIRS[@]}"
do
  DIR_NAME=$(basename "${DIR}" | sed 's/\s\+/_/g')
  SYMLINK_NAME="${DIR_NAME/_-_*}"
  SYMLINK_PATH="${HOME}/${SYMLINK_NAME,,}"
  creating "symlink ${SYMLINK_NAME,,} in home directory"
  [ -L "${SYMLINK_PATH}" ] && rm -f "${SYMLINK_PATH}" &>/dev/null
  ln -s "${DIR}" "${SYMLINK_PATH}" &>/dev/null && pass || fail
done

# Fix the WSL2 / Debian clock issue.

$SUDO hwclock -s

# Run the debian setup script.

source $BIN_DIR/setup_debian.sh
