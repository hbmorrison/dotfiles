# Configuration.

TIMESTAMP=`date '+%Y%M%dT%H%M'`
PACKAGES="bash-completion curl fail2ban git git-flow jq man-db net-tools \
  python3-systemd sudo vim"
SSHD_CONFIG="/etc/ssh/sshd_config"
TAILSCALE_ARGS="--accept-routes --accept-risk=all"
PUBLIC_SSH_KEYS="${BASE_DIR}/etc/public_ssh_keys"

NON_ROOT_USER="hannah"
NON_ROOT_ADMIN_GROUPS="sudo,users"
NON_ROOT_HOME="/home/${NON_ROOT_USER}"
NON_ROOT_SSH_DIR="${NON_ROOT_HOME}/.ssh"
NON_ROOT_AUTHORIZED_KEYS="${NON_ROOT_SSH_DIR}/authorized_keys"
NON_ROOT_LOCAL_DIR="${NON_ROOT_HOME}/.local"
NON_ROOT_DOTFILES="${NON_ROOT_LOCAL_DIR}/dotfiles"

# Add docker to the list of admin groups if it exists.

if grep ^docker: /etc/group &>/dev/null
then
  NON_ROOT_ADMIN_GROUPS="${NON_ROOT_ADMIN_GROUPS},docker"
fi

# Check that this script is being run by root.

if [ `id -u` -ne 0 ]
then
  echo "Error: run as root"
  exit 1
fi

# Work out which OS and terminal is being used.

case $ID in
  ubuntu)
    SHELL_ENVIRONMENT="ubuntu"
    ;;
  debian)
    SHELL_ENVIRONMENT="debian"
    dpkg -s proxmox-ve &>/dev/null && SHELL_ENVIRONMENT="pve"
    dpkg -s proxmox-backup-server &>/dev/null && SHELL_ENVIRONMENT="pbs"
    ;;
  *)
    echo "Error: ${SETUP_SCRIPT} ${SUB_SCRIPT} does not support OS $ID"
    exit 1
esac

# Install required packages.

apt update -y
apt install -y $PACKAGES

# Make a backup copy of the sshd_config file.

cp $SSHD_CONFIG "${SSHD_CONFIG}.${TIMESTAMP}"

case $SHELL_ENVIRONMENT in

  # Keep root password logins and TCP forwarding enabled on Proxmox VE.

  pve)
    sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin yes/' $SSHD_CONFIG
    sed -i -e '/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding yes/' $SSHD_CONFIG
    ;;

  # Disable root password logins and TCP forwarding elsewhere.

  debian|ubuntu|pbs)
    sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin without-password/' $SSHD_CONFIG
    sed -i -e '/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding no/' $SSHD_CONFIG
    ;;

esac

# Lock down authentication and forwarding.

sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' $SSHD_CONFIG
sed -i -e '/^\(#\|\)KbdInteractiveAuthentication/s/^.*$/KbdInteractiveAuthentication no/' $SSHD_CONFIG
sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' $SSHD_CONFIG
sed -i -e '/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries 2/' $SSHD_CONFIG
sed -i -e '/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/' $SSHD_CONFIG
sed -i -e '/^\(#\|\)AllowAgentForwarding/s/^.*$/AllowAgentForwarding no/' $SSHD_CONFIG
sed -i -e '/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh\/authorized_keys/' $SSHD_CONFIG

# Only allow root and the non-root user to connect via ssh.

sed -i -e 's/^AllowUsers/#AllowUsers/' $SSHD_CONFIG
sed -i -e "\$a AllowUsers root ${NON_ROOT_USER}" $SSHD_CONFIG

# Restart sshd to pick up the changes.

systemctl restart sshd

# Install and configure tailscale.

systemctl status tailscaled.service &>/dev/null
if [ $? -eq 4 ]
then
  $BIN_DIR/setup install tailscale
  tailscale set $TAILSCALE_ARGS
fi

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
    ufw --force enable
esac

# Configure fail2ban for sshd.

cp $BASE_DIR/etc/jail.d/default.local /etc/fail2ban/jail.d/
cp $BASE_DIR/etc/jail.d/sshd.local /etc/fail2ban/jail.d/

systemctl enable --now fail2ban

# Create the non-root user if needed.

if ! grep ^$NON_ROOT_USER: /etc/passwd >/dev/null 2>&1
then
  useradd -s /bin/bash -U -G $NON_ROOT_ADMIN_GROUPS -m $NON_ROOT_USER
fi

# Ensure that sudo access requires a password.

cp /etc/sudoers /etc/sudoers.$TIMESTAMP

sed -i -e '/^\(#\|\)\s*\%sudo\s\s*ALL.*ALL$/s/^.*$/\%sudo ALL=(ALL:ALL) ALL/' /etc/sudoers

for SUDO_ITEM in $(ls -1 /etc/sudoers.d/*)
do
  sed -i -e '/NOPASSWD:/s/NOPASSWD://' $SUDO_ITEM
done

# Check that the user ssh directory and authorized_keys file exist.

if [ ! -d $NON_ROOT_SSH_DIR ]
then
  su -c "mkdir -m 0700 $NON_ROOT_SSH_DIR" $NON_ROOT_USER
fi

if [ ! -f $NON_ROOT_AUTHORIZED_KEYS ]
then
  su -c "touch $NON_ROOT_AUTHORIZED_KEYS" $NON_ROOT_USER
fi

# Go through each ssh key and add it to authorized_keys if not present.

while read -r TYPE KEY COMMENT
do
  if ! grep "${KEY}" $NON_ROOT_AUTHORIZED_KEYS &>/dev/null
  then
    echo -n "Adding '${COMMENT}' to ${NON_ROOT_USER}'s authorized ssh keys..."
    echo "${TYPE} ${KEY} ${COMMENT}" >> $NON_ROOT_AUTHORIZED_KEYS
    echo "Done"
  fi
done < "${PUBLIC_SSH_KEYS}"

# Configure the non-root user shell.

if [ ! -d $NON_ROOT_LOCAL_DIR ]
then
  su -c "mkdir -m 0755 $NON_ROOT_LOCAL_DIR" $NON_ROOT_USER
fi

if [ ! -d $NON_ROOT_DOTFILES ]
then
  cp -r $BASE_DIR $NON_ROOT_DOTFILES
  chown -R $NON_ROOT_USER:$NON_ROOT_USER $NON_ROOT_DOTFILES
else
  su -c "git -C $NON_ROOT_DOTFILES pull" $NON_ROOT_USER
fi

if [ ! -x $NON_ROOT_DOTFILES/bin/setup ]
then
  echo "Error: dotfiles setup script not found for $NON_ROOT_USER"
  exit 1
fi

su -c "$NON_ROOT_DOTFILES/bin/setup shell" $NON_ROOT_USER

# Set the user's password.

if [ `grep ^$NON_ROOT_USER: /etc/shadow 2>/dev/null | cut -d: -f2 | wc -c` -lt 3 ]
then
  while true
  do
    read -s -p "${SETUP_SCRIPT} ${SUB_SCRIPT}: enter new password for ${NON_ROOT_USER}: " PASSWORD
    echo
    read -s -p "${SETUP_SCRIPT} ${SUB_SCRIPT}: retype new password for ${NON_ROOT_USER}: " RETYPE
    echo
    if [ "${PASSWORD}" != "${RETYPE}" ]
    then
      echo "${SETUP_SCRIPT} ${SUB_SCRIPT}: passwords do not match."
      continue
    fi
    if [ "${PASSWORD}" = "" ]
    then
      echo "${SETUP_SCRIPT} ${SUB_SCRIPT}: password must not be empty."
      continue
    fi
    if echo "${NON_ROOT_USER}:${PASSWORD}" | chpasswd
    then
      echo "${SETUP_SCRIPT} ${SUB_SCRIPT}: password for ${NON_ROOT_USER} updated successfully"
      break
    fi
  done
fi

# Update the non-root user with the correct shell and groups.

usermod -U -s /bin/bash -aG $NON_ROOT_ADMIN_GROUPS $NON_ROOT_USER
