# Configuration.

DEFAULT_GROUPS="adm,cdrom,sudo,dip,plugdev"

# Get the name of the new clone.

CLONE=$1
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

# Get the name of the default WSL distro, the location of its install directory
# and the full path to its tarball.

DEFAULT_DISTRO=$(wsl.exe -l --running | tr -d '[\0\r]' | awk '/(Default)/ {print $1}')
DEFAULT_DISTRO_INSTALL_DIR=$(powershell.exe -Command "Get-ChildItem 'HKCU:\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\CurrentVersion\\AppModel\\Repository\\Packages\\*${DEFAULT_DISTRO}*' | ForEach-Object { Write-Output (\$_ | Get-ItemProperty -Name PackageRootFolder).PackageRootFolder }" | tr -d '[\0\r]')
DEFAULT_DISTRO_TARBALL="${DEFAULT_DISTRO_INSTALL_DIR//\\//}/install.tar.gz"

# Work out the name for the new distro.

DISTRO_NAME="${DEFAULT_DISTRO}-${CLONE}"

DISTRO_NAME_CHECK=$(wsl.exe -l | tr -d '[\0\r]' | awk "/^${DISTRO_NAME}/ {print \$1}")
if [ -z ${DISTRO_NAME_CHECK:+z} ]
then
  echo "Error: ${DISTRO_NAME} already exists"
  exit 1
fi

# Create the new distro.

echo "Creating ${DISTRO_NAME}:"
echo wsl.exe --import $DISTRO_NAME "C:/WSL/${DISTRO_NAME}" "${DEFAULT_DISTRO_TARBALL}" --version 2

# Create the current user in the new distro.

echo wsl.exe -d $DISTRO_NAME -u root --cd / -- /usr/sbin/useradd -m -G $DEFAULT_GROUPS -s /bin/bash $USER

# Set the password for the user.

echo "Set password for user ${USER} in ${DISTRO_NAME}:"
echo wsl.exe -d $DISTRO_NAME -u root --cd / -- /usr/bin/passwd $USER

# Set the user as the default user for the distro.

echo "Setting user ${USER} in ${DISTRO_NAME} as the default user:"
wsl.exe -d $DISTRO_NAME -u root --cd / -- /bin/printf "\\\n[user]\\\ndefault=${USER}\\\\n" \>\> /etc/wsl.conf
