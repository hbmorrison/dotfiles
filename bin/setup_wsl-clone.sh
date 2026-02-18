#!/bin/bash

# Configuration.

DEFAULT_GROUPS="adm,cdrom,sudo,dip,plugdev"

# Get the suffix for the new clone.

SUFFIX=$1
if [ -z "${1:+z}" ]
then
  echo "Usage: ${SETUP_SCRIPT} ${SUB_SCRIPT} <name of WSL clone>"
  exit 1
fi

# Make sure that the VHDX directory exists.

if [ ! -d /mnt/c/WSL ]
then
  mkdir -p /mnt/c/WSL
fi

# Enable windows binary interop on this distro permanently to avoid any exec
# format error drama.

wsl.exe -d $WSL_DISTRO_NAME -u root --cd / -- /bin/echo ":WSLInterop:M::MZ::/init:PF" \> /usr/lib/binfmt.d/WSLInterop.conf
wsl.exe -d $WSL_DISTRO_NAME -u root --cd / -- /bin/systemctl restart systemd-binfmt

# Get the name of the default WSL distro, the location of its install directory
# and the full path to its tarball.

DEFAULT_DISTRO=$(wsl.exe -l --running | tr -d '[\0\r]' | awk '/(Default)/ {print $1}')
DEFAULT_DISTRO_INSTALL_DIR=$(powershell.exe -Command "Get-ChildItem 'HKCU:\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\CurrentVersion\\AppModel\\Repository\\Packages\\*${DEFAULT_DISTRO}*' | ForEach-Object { Write-Output (\$_ | Get-ItemProperty -Name PackageRootFolder).PackageRootFolder }" | tr -d '[\0\r]')
DEFAULT_DISTRO_TARBALL="${DEFAULT_DISTRO_INSTALL_DIR//\\//}/install.tar.gz"

# Check that the tarball is there.

if [ ! -f "${DEFAULT_DISTRO_TARBALL/C://mnt/c}" ]
then
  echo "Error: could not locate distribution tarball for ${DEFAULT_DISTRO}"
  exit 1
fi

# Work out the name for the new distro.

DISTRO_NAME="${DEFAULT_DISTRO}-${SUFFIX}"

DISTRO_NAME_CHECK=$(wsl.exe -l | tr -d '[\0\r]' | awk "/^${DISTRO_NAME}$/ {print \$1}")
if [ ! -z ${DISTRO_NAME_CHECK:+z} ]
then
  echo "Error: ${DISTRO_NAME} already exists"
  exit 1
fi

# Create the new distro.

echo "Clone ${DISTRO_NAME} from ${DEFAULT_DISTRO}:"
wsl.exe --import $DISTRO_NAME "C:/WSL/${DISTRO_NAME}" "${DEFAULT_DISTRO_TARBALL}" --version 2

# Create the current user in the new distro and set a password.

wsl.exe -d $DISTRO_NAME -u root --cd / -- /usr/sbin/useradd -m -G $DEFAULT_GROUPS -s /bin/bash $USER
echo "Set password for new user ${USER} in ${DISTRO_NAME}:"
wsl.exe -d $DISTRO_NAME -u root --cd / -- /usr/bin/passwd $USER

# Set the user as the default user for the distro.

echo "Set user ${USER} in ${DISTRO_NAME} as the default user:"
wsl.exe -d $DISTRO_NAME -u root --cd / -- /bin/printf "\\\n[user]\\\ndefault=${USER}\\\\n" \>\> /etc/wsl.conf
echo "The operation completed successfully."

# Enable windows binary interop on the new distro permanently.

wsl.exe -d $WSL_DISTRO_NAME -u root --cd / -- /bin/echo ":WSLInterop:M::MZ::/init:PF" \> /usr/lib/binfmt.d/WSLInterop.conf

# Terminate the new distro so that it can reboot and pick up its new settings.

echo "Shut down ${DISTRO_NAME} to pick up new settings:"
wsl.exe -t $DISTRO_NAME
