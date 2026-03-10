# Configuration.

TIMESTAMP=$(date '+%Y%M%dT%H%M')
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

[ $(id -u) -ne 0 ] && fail "run as root"

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
    fail "setup ${SCRIPT} does not support OS $ID"
esac

# Install required packages.

notice "updating package lists"
apt update -y && pass || fail
notice "installing packages"
apt install -y $PACKAGES && pass || fail

# Make a backup copy of the sshd_config file.

notice "backing up ssh config"
cp $SSHD_CONFIG "${SSHD_CONFIG}.${TIMESTAMP}" && pass || fail

case $SHELL_ENVIRONMENT in

  # Keep root password logins and TCP forwarding enabled on Proxmox VE.

  pve)
    notice "permitting ssh root login and forwarding"
    sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin yes/' $SSHD_CONFIG
    sed -i -e '/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding yes/' $SSHD_CONFIG
    pass
    ;;

  # Disable root password logins and TCP forwarding elsewhere.

  debian|ubuntu|pbs)
    notice "disallow ssh root login and forwarding"
    sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin without-password/' $SSHD_CONFIG
    sed -i -e '/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding no/' $SSHD_CONFIG
    pass
    ;;

esac

# Lock down authentication and forwarding.

notice "disallowing non-PAM ssh logins"
sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' $SSHD_CONFIG
sed -i -e '/^\(#\|\)KbdInteractiveAuthentication/s/^.*$/KbdInteractiveAuthentication no/' $SSHD_CONFIG
sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' $SSHD_CONFIG
pass
notice "disallowing ssh X11 forwarding and agent forwarding"
sed -i -e '/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/' $SSHD_CONFIG
sed -i -e '/^\(#\|\)AllowAgentForwarding/s/^.*$/AllowAgentForwarding no/' $SSHD_CONFIG
pass
notice "limiting authentication retries"
sed -i -e '/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries 2/' $SSHD_CONFIG
pass
notice "limiting naming of authorized_keys files"
sed -i -e '/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh\/authorized_keys/' $SSHD_CONFIG
pass

# Only allow root and the non-root user to connect via ssh.

notice "only allow root and ${NON_ROOT_USER} ssh logins"
sed -i -e 's/^AllowUsers/#AllowUsers/' $SSHD_CONFIG
sed -i -e "\$a AllowUsers root ${NON_ROOT_USER}" $SSHD_CONFIG
pass

# Restart sshd to pick up the changes.

notice "restarting sshd"
systemctl restart sshd && pass || fail

# Install and configure tailscale.

systemctl status tailscaled.service &>/dev/null
if [ $? -eq 4 ]
then
  source $BIN_DIR/setup_install.sh tailscale
  tailscale set $TAILSCALE_ARGS
fi

# Secure tailscaled.

if [ -f /etc/default/tailscaled ]
then
  notice "backing up Tailscale config"
  cp /etc/default/tailscaled /etc/default/tailscaled.$TIMESTAMP
  pass
  notice "adding extra flags to Tailscale config"
  sed -i -e '/^FLAGS=/s/""/"--no-logs-no-support"/' /etc/default/tailscaled \
   && pass || fail
  if diff /etc/default/tailscaled /etc/default/tailscaled.$TIMESTAMP &>/dev/null
  then
    notice "restarting tailscaled"
    systemctl restart tailscaled.service && pass || fail
  fi
fi

# Only configure ufw on non-Proxmox hosts.

case $SHELL_ENVIRONMENT in
  debian|ubuntu)
    notice "installing ufw"
    apt install -y ufw && pass || fail
    notice "allowing ssh access in ufw"
    ufw allow 22/tcp comment 'allow ssh' && pass || fail
    notice "enabling ufw firewall"
    ufw --force enable && pass || fail
esac

# Configure fail2ban for sshd.

notice "copying ssh fail2ban jails"
cp $BASE_DIR/etc/jail.d/default.local /etc/fail2ban/jail.d/
cp $BASE_DIR/etc/jail.d/sshd.local /etc/fail2ban/jail.d/
pass

notice "enabling fail2ban"
systemctl enable --now fail2ban && pass || fail

# Create the non-root user if needed.

if ! grep ^$NON_ROOT_USER: /etc/passwd &>/dev/null
then
  notice "adding user ${NON_ROOT_USER}"
  useradd -s /bin/bash -U -G $NON_ROOT_ADMIN_GROUPS -m $NON_ROOT_USER \
   && pass || fail
fi

# Ensure that sudo access requires a password.

notice "backing up sudoers file"
cp /etc/sudoers /etc/sudoers.$TIMESTAMP
pass

notice "ensuring that all sudo root actions require a password"
sed -i -e '/^\(#\|\)\s*\%sudo\s\s*ALL.*ALL$/s/^.*$/\%sudo ALL=(ALL:ALL) ALL/' /etc/sudoers \
 && pass || fail

notice "removing NOPASSWD from additional sudo rules"
for ITEM in $(ls -1 /etc/sudoers.d/*)
do
  sed -i -e '/NOPASSWD:/s/NOPASSWD://' $ITEM
done
pass

# Check that the user ssh directory and authorized_keys file exist.

notice "preparing ${NON_ROOT_USER} home directory"
[ ! -d $NON_ROOT_SSH_DIR ] && su -l -c "mkdir -m 0700 $NON_ROOT_SSH_DIR" $NON_ROOT_USER
[ ! -f $NON_ROOT_AUTHORIZED_KEYS ] && su -l -c "touch $NON_ROOT_AUTHORIZED_KEYS" $NON_ROOT_USER
pass

# Go through each ssh key and add it to authorized_keys if not present.

while read -r TYPE KEY COMMENT
do
  if ! grep "${KEY}" $NON_ROOT_AUTHORIZED_KEYS &>/dev/null
  then
    notice "Adding '${COMMENT}' as an authorized key for ${NON_ROOT_USER}"
    echo "${TYPE} ${KEY} ${COMMENT}" >> $NON_ROOT_AUTHORIZED_KEYS \
     && pass || fail
  fi
done < "${PUBLIC_SSH_KEYS}"

# Configure the non-root user shell.

[ ! -d $NON_ROOT_LOCAL_DIR ] &&  su -l -c "mkdir -m 0755 $NON_ROOT_LOCAL_DIR" $NON_ROOT_USER

if [ ! -d $NON_ROOT_DOTFILES ]
then
  notice "copying dotfiles repo to ${NON_ROOT_USER}'s home directory"
  cp -r $BASE_DIR $NON_ROOT_DOTFILES && pass || fail
  notice "fixing ownership"
  chown -R $NON_ROOT_USER:$NON_ROOT_USER $NON_ROOT_DOTFILES && pass || fail
else
  notice "updating dotfiles repo for ${NON_ROOT_USER}"
  su -l -c "git -C $NON_ROOT_DOTFILES pull" $NON_ROOT_USER && pass || fail
fi

[ -x $NON_ROOT_DOTFILES/bin/setup ] \
 || fail "dotfiles setup script not found for $NON_ROOT_USER"

su -l -c "$NON_ROOT_DOTFILES/bin/setup shell" $NON_ROOT_USER

# Set the user's password.

if [ $(grep ^$NON_ROOT_USER: /etc/shadow 2>/dev/null | cut -d: -f2 | wc -c) -lt 3 ]
then
  while true
  do
    read -s -p "setup ${SCRIPT}: enter new password for ${NON_ROOT_USER}: " PASSWORD
    echo
    read -s -p "setup ${SCRIPT}: retype new password for ${NON_ROOT_USER}: " RETYPE
    echo
    if [ "${PASSWORD}" != "${RETYPE}" ]
    then
      echo "setup ${SCRIPT}: passwords do not match."
      continue
    fi
    if [ "${PASSWORD}" = "" ]
    then
      echo "setup ${SCRIPT}: password must not be empty."
      continue
    fi
    if echo "${NON_ROOT_USER}:${PASSWORD}" | chpasswd
    then
      echo "setup ${SCRIPT}: password for ${NON_ROOT_USER} updated successfully"
      break
    fi
  done
fi

# Update the non-root user with the correct shell and groups.

notice "add ${NON_ROOT_USER} to admin groups"
usermod -U -s /bin/bash -aG $NON_ROOT_ADMIN_GROUPS $NON_ROOT_USER \
 && pass || fail
