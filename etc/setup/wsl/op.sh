#!/bin/bash

# Configuration.

WINGET_INSTALL_ARGS="--silent --accept-package-agreements --accept-source-agreements"

# Get Windows environment variables.

WIN_LOCALAPPDATA=$(powershell.exe '$Env:LOCALAPPDATA' | tr -d '\r')
LOCALAPPDATA=$(wslpath -u "${WIN_LOCALAPPDATA}")

# Windows directories.

WINGET_PACKAGES_DIR="${LOCALAPPDATA}/Microsoft/WinGet/Packages"
OP_CONFIG_DIR="${LOCALAPPDATA}/1Password/config/ssh"

# Winget packages to install.

WINGET_PACKAGES=(
  "AgileBits.1Password.CLI"
)

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
for PACKAGE in "${SYMLINK_WINGET_PACKAGES[@]}"
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

# Configure 1Password CLI.

notice "copying 1Password agent config"
[ -d "${OP_CONFIG_DIR}" ] || mkdir -p "${OP_CONFIG_DIR}" &>/dev/null \
 || fatal "could not create ${OP_CONFIG_DIR}"
cp -f "${ETC_DIR}/wsl/agent.toml" "${OP_CONFIG_DIR}/agent.toml" &>/dev/null \
 || fatal "could not copy agent.toml to ${OP_CONFIG_DIR}"
pass
