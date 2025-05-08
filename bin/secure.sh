#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)
SCRIPT_NAME=$(basename $THIS_SCRIPT)

# Configuration.

NON_ROOT_USER=hannah
TIMESTAMP=`date '+%Y%M%dT%H%M'`

# Check that this script is being run by root.

if [ `id -u` -ne 0 ]
then
  echo "Error: run as root"
  exit 1
fi

# Work out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  MSYS*|MINGW64*)            SHELL_ENVIRONMENT="gitbash" ;;
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos" ;;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl" ;;
  *Debian*)                  SHELL_ENVIRONMENT="debian" ;;
  *Ubuntu*)                  SHELL_ENVIRONMENT="ubuntu" ;;
  *Red\ Hat*)                SHELL_ENVIRONMENT="redhat" ;;
esac

case $ID in
  debian|ubuntu)
      apt update
      ;;
  *)
    echo "Error: operating system not supported"
    exit 1
esac

# Create the non-root user if needed.

USER_EXISTS=`grep "^${NON_ROOT_USER}:" /etc/passwd`

if [ "x${USER_EXISTS}" = "x" ]
then
  case $ID in
    debian|ubuntu)
      apt install -y sudo
      useradd -s /bin/bash -U -G users,sudo -m $NON_ROOT_USER
      ;;
  esac
fi

# Check that the sudo group exists.

SUDO_GROUP_EXISTS=`grep "^sudo:" /etc/group`

if [ "x${SUDO_GROUP_EXISTS}" = "x" ]
then
  groupadd sudo
fi

# Check that sudo rights are granted to the sudo group.

cp /etc/sudoers /etc/sudoers.$TIMESTAMP

sed -i -e '/^\(#\|\)\s*\%sudo\s\s*ALL.*ALL$/s/^.*$/\%sudo ALL=(ALL:ALL) ALL/' /etc/sudoers

# Remove NOPASSWD from sudoers.d rules.

for SUDO_ITEM in $(ls -1 /etc/sudoers.d/*)
do
  echo $SUDO_ITEM
  sed -i -e '/NOPASSWD:/s/NOPASSWD://' $SUDO_ITEM
done
exit 1

# Create the non-root user.

useradd -s /bin/bash -U -G users,sudo -m $NON_ROOT_USER

# Configure the user home directory.

if [ ! -d /home/$NON_ROOT_USER/dotfiles ]
then
  cp -r $BASE_DIR /home/$NON_ROOT_USER/dotfiles
  chown -R $NON_ROOT_USER:$NON_ROOT_USER /home/$NON_ROOT_USER/dotfiles
fi

if [ ! -x /home/$NON_ROOT_USER/dotfiles/bin/update.sh ]
then
  echo "Error: dotfiles update script not found"
  exit 1
fi

su -c "/home/$NON_ROOT_USER/dotfiles/bin/update.sh" - $NON_ROOT_USER

if [ ! -x /home/$NON_ROOT_USER/dotfiles/bin/keys.sh ]
then
  echo "Error: dotfiles keys script not found"
  exit 1
fi

su -c "/home/$NON_ROOT_USER/dotfiles/bin/keys.sh" - $NON_ROOT_USER

# Secure sshd.

case $ID in
  debian|ubuntu)
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.$TIMESTAMP
    sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin without-password/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)KbdInteractiveAuthentication/s/^.*$/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries 2/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding yes/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)AllowAgentForwarding/s/^.*$/AllowAgentForwarding no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
    sed -i -e 's/^AllowUsers/#AllowUsers/' /etc/ssh/sshd_config
    sed -i -e "\$a AllowUsers root ${NON_ROOT_USER}" /etc/ssh/sshd_config
    systemctl restart sshd
    ;;
esac

# Set the user's password.

while true
do
  read -s -p "${SCRIPT_NAME} new password: " PASSWORD
  echo
  read -s -p "${SCRIPT_NAME} retype new password: " RETYPE
  echo
  if [ "${PASSWORD}" != "${RETYPE}" ]
  then
    echo "${SCRIPT_NAME} sorry, passwords do not match."
    continue
  fi
  if [ "${PASSWORD}" = "" ]
  then
    echo "${SCRIPT_NAME} sorry, password must not be empty."
    continue
  fi
  if echo "${NON_ROOT_USER}:${PASSWORD}" | chpasswd
  then
    echo "${SCRIPT_NAME} password updated successfully"
    break
  fi
done
