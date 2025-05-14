#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)
SCRIPT_NAME=$(basename $THIS_SCRIPT)

# Configuration.

NON_ROOT_USER=hannah
TIMESTAMP=`date '+%Y%M%dT%H%M'`
DEBIAN_PACKAGES="bash-completion curl fail2ban git git-flow vim"

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
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.$TIMESTAMP
    # Keep root password logins enabled on Proxmox VE for cluster management.
    if grep /etc/pve /proc/mounts
    then
      sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
    else
      sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
    fi
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

# Configure fail2ban for sshd.

echo > /etc/fail2ban/jail.local <<SSHD_JAIL
[sshd]
enabled = true
banaction = iptables-multiport
SSHD_JAIL

systemctl enable fail2ban

# Configure ufw on non-Proxmox hosts.

if ! grep /etc/pve /proc/mounts
then
  apt install -y ufw
  ufw allow 22/tcp     # allow ssh
  ufw allow 41641/udp  # allow direct tailscale connections
  ufw enable
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
  sed -i -e '/NOPASSWD:/s/NOPASSWD://' $SUDO_ITEM
done

# Update the non-root user with the correct shell and groups.

usermod -s /bin/bash -U -G users,sudo $NON_ROOT_USER

# Configure the user home directory.

if [ ! -d /home/$NON_ROOT_USER/dotfiles ]
then
  cp -r $BASE_DIR /home/$NON_ROOT_USER/dotfiles
  chown -R $NON_ROOT_USER:$NON_ROOT_USER /home/$NON_ROOT_USER/dotfiles
fi

if [ ! -x /home/$NON_ROOT_USER/dotfiles/bin/dotfiles.sh ]
then
  echo "Error: dotfiles dotfiles script not found"
  exit 1
fi

su -c "/home/$NON_ROOT_USER/dotfiles/bin/dotfiles.sh" - $NON_ROOT_USER

if [ ! -x /home/$NON_ROOT_USER/dotfiles/bin/keys.sh ]
then
  echo "Error: dotfiles keys script not found"
  exit 1
fi

su -c "/home/$NON_ROOT_USER/dotfiles/bin/keys.sh" - $NON_ROOT_USER

# Set the user's password.

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
