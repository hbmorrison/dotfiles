#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)
SCRIPT_NAME=$(basename $THIS_SCRIPT)

# Configuration.

NON_ROOT_USER=hannah
NON_ROOT_DOTFILES="/home/${NON_ROOT_USER}/.dotfiles"
TIMESTAMP=`date '+%Y%M%dT%H%M'`
DEBIAN_PACKAGES="bash-completion curl fail2ban git python3-systemd sudo vim"

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
  *aarch64-linux-gcc*)
    . /etc/os-release
    case $ID in
      debian)                SHELL_ENVIRONMENT="debian" ;;
    esac
    ;;
esac

case $SHELL_ENVIRONMENT in
  debian|ubuntu)
      apt update
      apt install -y $DEBIAN_PACKAGES
      ;;
  *)
    echo "Error: operating system not supported"
    exit 1
esac

# Secure sshd.

case $SHELL_ENVIRONMENT in
  debian|ubuntu)

    # Keep a backup copy of the sshd_config file.

    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.$TIMESTAMP

    # Keep root password logins and TCP forwarding enabled on Proxmox VE for cluster management.

    if grep /etc/pve /proc/mounts
    then
      sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
      sed -i -e '/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding yes/' /etc/ssh/sshd_config
    else
      sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin without-password/' /etc/ssh/sshd_config
      sed -i -e '/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding no/' /etc/ssh/sshd_config
    fi

    # Lock down authentication and forwarding.

    sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)KbdInteractiveAuthentication/s/^.*$/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries 2/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)AllowAgentForwarding/s/^.*$/AllowAgentForwarding no/' /etc/ssh/sshd_config

    # Ensure that authorized_keys will be read.

    sed -i -e '/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config

    # Only allow root and the non-root user access.

    sed -i -e 's/^AllowUsers/#AllowUsers/' /etc/ssh/sshd_config
    sed -i -e "\$a AllowUsers root ${NON_ROOT_USER}" /etc/ssh/sshd_config

    # Restart sshd to pick up the changes.

    systemctl restart sshd
    ;;

esac

# Configure ufw on non-Proxmox hosts.

if ! grep /etc/pve /proc/mounts
then
  apt install -y ufw
  ufw allow 22/tcp     # allow ssh
  ufw allow 41641/udp  # allow direct tailscale connections
  ufw --force enable
fi

# Configure fail2ban for sshd on non-Proxmox hosts.

if ! grep /etc/pve /proc/mounts
then
  cp $BASE_DIR/etc/fail2ban.local /etc/fail2ban/fail2ban.local
  cp $BASE_DIR/etc/jail.local /etc/fail2ban/jail.local
  systemctl enable fail2ban
  systemctl restart fail2ban
  journalctl -u fail2ban -n 10
fi

# Create the non-root user if needed.

USER_EXISTS=`grep "^${NON_ROOT_USER}:" /etc/passwd`

if [ "x${USER_EXISTS}" = "x" ]
then
  case $SHELL_ENVIRONMENT in
    debian|ubuntu)
      useradd -s /bin/bash -U -G users,sudo -m $NON_ROOT_USER
      ;;
  esac
fi

# Check that sudo rights are granted to the sudo group without NOPASSWD.

cp /etc/sudoers /etc/sudoers.$TIMESTAMP

sed -i -e '/^\(#\|\)\s*\%sudo\s\s*ALL.*ALL$/s/^.*$/\%sudo ALL=(ALL:ALL) ALL/' /etc/sudoers

# Remove NOPASSWD from sudoers.d rules.

for SUDO_ITEM in $(ls -1 /etc/sudoers.d/*)
do
  sed -i -e '/NOPASSWD:/s/NOPASSWD://' $SUDO_ITEM
done

# Update the non-root user with the correct shell and groups.

usermod -s /bin/bash -U -G users,sudo $NON_ROOT_USER

# Configure the user home directory.

if [ ! -d $NON_ROOT_DOTFILES ]
then
  cp -r $BASE_DIR $NON_ROOT_DOTFILES
  chown -R $NON_ROOT_USER:$NON_ROOT_USER $NON_ROOT_DOTFILES
fi

if [ ! -x $NON_ROOT_DOTFILES/bin/dotfiles.sh ]
then
  echo "Error: dotfiles dotfiles script not found"
  exit 1
fi

su -c "$NON_ROOT_DOTFILES/bin/dotfiles.sh" - $NON_ROOT_USER

if [ ! -x $NON_ROOT_DOTFILES/bin/keys.sh ]
then
  echo "Error: dotfiles keys script not found"
  exit 1
fi

su -c "$NON_ROOT_DOTFILES/bin/keys.sh" - $NON_ROOT_USER

# Set the user's password.

if [ `grep $NON_ROOT_USER /etc/shadow | cut -d: -f2 | wc -c` -lt 3 ]
then
  while true
  do
    read -s -p "${SCRIPT_NAME} new password for ${NON_ROOT_USER}: " PASSWORD
    echo
    read -s -p "${SCRIPT_NAME} retype new password for ${NON_ROOT_USER}: " RETYPE
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
      echo "${SCRIPT_NAME} password for ${NON_ROOT_USER} updated successfully"
      break
    fi
  done
fi
