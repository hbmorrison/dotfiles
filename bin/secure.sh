#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)
SCRIPT_NAME=$(basename $THIS_SCRIPT)

# Configuration.

NON_ROOT_USER=hannah
NON_ROOT_DOTFILES="/home/${NON_ROOT_USER}/dotfiles"
TIMESTAMP=`date '+%Y%M%dT%H%M'`
DEBIAN_PACKAGES="bash-completion curl fail2ban git python3-systemd sudo vim"
TAILSCALE_ARGS="--accept-risk all --advertise-tags tag:secure"
ADMIN_GROUPS="sudo,users"

# Add docker to the list of admin groups if it exists.

if grep ^docker: /etc/group >/dev/null 2>&1
then
  ADMIN_GROUPS="${ADMIN_GROUPS},docker"
fi

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
  *build@proxmox*)           SHELL_ENVIRONMENT="pve" ;;
  *Debian*)                  SHELL_ENVIRONMENT="debian" ;;
  *Ubuntu*)                  SHELL_ENVIRONMENT="ubuntu" ;;
  *Red\ Hat*)                SHELL_ENVIRONMENT="redhat" ;;
  # Detect debian on ARM.
  *aarch64-linux-gcc*)
    if [ -f /etc/os-release ]
    then
      . /etc/os-release
      case $ID in
        debian)              SHELL_ENVIRONMENT="debian" ;;
      esac
    fi
    ;;
  *)
    echo "Error: operating system not detected"
    exit 1
esac

case $SHELL_ENVIRONMENT in
  debian|ubuntu|pve)
      apt update
      apt install -y $DEBIAN_PACKAGES
      ;;
  *)
    echo "Error: operating system not supported"
    exit 1
esac

# Make a backup copy of the sshd_config file.

case $SHELL_ENVIRONMENT in
  debian|ubuntu|pve)
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.$TIMESTAMP
esac

# Keep root password logins and TCP forwarding enabled on Proxmox VE cluster
# management.

case $SHELL_ENVIRONMENT in
  pve)
    sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding yes/' /etc/ssh/sshd_config
  debian|ubuntu)
    sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin without-password/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding no/' /etc/ssh/sshd_config
esac

# Lock down authentication and forwarding.

case $SHELL_ENVIRONMENT in
  debian|ubuntu|pve)
    sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)KbdInteractiveAuthentication/s/^.*$/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries 2/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)AllowAgentForwarding/s/^.*$/AllowAgentForwarding no/' /etc/ssh/sshd_config
    sed -i -e '/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
    sed -i -e 's/^AllowUsers/#AllowUsers/' /etc/ssh/sshd_config
    sed -i -e "\$a AllowUsers root ${NON_ROOT_USER}" /etc/ssh/sshd_config
esac

# Restart sshd to pick up the changes.

case $SHELL_ENVIRONMENT in
  debian|ubuntu|pve)
    systemctl restart sshd
    ;;
esac

# Install and configure tailscale.

case $SHELL_ENVIRONMENT in
  debian|ubuntu|pve)
    systemctl status tailscaled.service >/dev/null 2>&1
    if [ $? -eq 4 ]
    then
      $BASE_DIR/bin/tailscale.sh >/dev/null
      tailscale up $TAILSCALE_ARGS
    fi
    ;;
esac

# Secure tailscaled.

if [ -f /etc/default/tailscaled ]
then
  cp /etc/default/tailscaled /etc/default/tailscaled.$TIMESTAMP
  sed -i -e '/^FLAGS=/s/""/"--no-logs-no-support"/' /etc/default/tailscaled
  diff  /etc/default/tailscaled /etc/default/tailscaled.$TIMESTAMP >/dev/null 2>&1
  if [ $? -ne 0 ]
  then
    systemctl restart tailscaled.service
  fi
fi

# Only configure ufw on non-Proxmox hosts.

case $SHELL_ENVIRONMENT in
  debian|ubuntu)
    apt install -y ufw
    ufw allow 22/tcp comment 'allow ssh'
    ufw allow 53/udp comment 'allow dns'
    ufw allow 53/tcp comment 'allow dns'
    ufw allow 68/udp comment 'allow dhcp'
    ufw allow 41641/udp 'allow tailscale'
    ufw --force enable
  fi
fi

# Configure fail2ban for sshd on non-Proxmox hosts.

case $SHELL_ENVIRONMENT in
  debian|ubuntu)
    cp $BASE_DIR/etc/fail2ban.local /etc/fail2ban/fail2ban.local
    cp $BASE_DIR/etc/jail.local /etc/fail2ban/jail.local
    systemctl enable fail2ban
    systemctl restart fail2ban
    journalctl -u fail2ban -n 10
esac

# Create the non-root user if needed.

if ! grep ^$NON_ROOT_USER: /etc/passwd >/dev/null 2>&1
then
  case $SHELL_ENVIRONMENT in
    debian|ubuntu|pve)
      useradd -s /bin/bash -U -G $ADMIN_GROUPS -m $NON_ROOT_USER
      ;;
  esac
fi

# Ensure that sudo requires a password.

cp /etc/sudoers /etc/sudoers.$TIMESTAMP

sed -i -e '/^\(#\|\)\s*\%sudo\s\s*ALL.*ALL$/s/^.*$/\%sudo ALL=(ALL:ALL) ALL/' /etc/sudoers

for SUDO_ITEM in $(ls -1 /etc/sudoers.d/*)
do
  sed -i -e '/NOPASSWD:/s/NOPASSWD://' $SUDO_ITEM
done

# Update the non-root user with the correct shell and groups.

usermod -s /bin/bash -U -G $ADMIN_GROUPS $NON_ROOT_USER

# Configure the user home directory.

if [ ! -d $NON_ROOT_DOTFILES ]
then
  cp -r $BASE_DIR $NON_ROOT_DOTFILES
  chown -R $NON_ROOT_USER:$NON_ROOT_USER $NON_ROOT_DOTFILES
else
  su -c "git -C $NON_ROOT_DOTFILES pull" - $NON_ROOT_USER
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

if [ `grep ^$NON_ROOT_USER: /etc/shadow 2>/dev/null | cut -d: -f2 | wc -c` -lt 3 ]
then
  while true
  do
    read -s -p "${SCRIPT_NAME} enter new password for ${NON_ROOT_USER}: " PASSWORD
    echo
    read -s -p "${SCRIPT_NAME} retype new password for ${NON_ROOT_USER}: " RETYPE
    echo
    if [ "${PASSWORD}" != "${RETYPE}" ]
    then
      echo "${SCRIPT_NAME} passwords do not match."
      continue
    fi
    if [ "${PASSWORD}" = "" ]
    then
      echo "${SCRIPT_NAME} password must not be empty."
      continue
    fi
    if echo "${NON_ROOT_USER}:${PASSWORD}" | chpasswd
    then
      echo "${SCRIPT_NAME} password for ${NON_ROOT_USER} updated successfully"
      break
    fi
  done
fi
