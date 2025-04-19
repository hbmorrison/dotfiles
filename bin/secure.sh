#!/bin/sh

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

NON_ROOT_USER=hannah

# Check that this script is being run by root.

if [ `id -u` -ne 0 ]
then
  echo "Error: run as root"
  exit 1
fi

# Work out which OS and terminal is being used.

source /etc/os-release 2> /dev/null

case $ID in
  debian)
      apt update
      ;;
  openwrt)
      opkg update
      ;;
  *)
    echo "Error: operating system not supported"
    exit 1
esac

# Create the non-root user if needed.

USER_EXISTS=`grep "^${NON_ROOT_USER}:" /etc/passwd`

if [ "x${USER_EXISTS}" == "x" ]
then
  case $ID in
    debian)
      apt install -y sudo
      ;;
    openwrt)
      opkg install shadow-useradd sudo
      ;;
  esac
  useradd -s /bin/bash -U -G users,sudo -m $NON_ROOT_USER
fi

# Configure the user home directory.

cp -r $BASE_DIR /home/$NON_ROOT_USER/dotfiles

#su -c "/home/$NON_ROOT_USER/dotfiles/bin/update.sh" $NON_ROOT_USER
#
## Secure sshd.
#
#sed -i -e '/^\(#\|\)PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
#sed -i -e '/^\(#\|\)PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
#sed -i -e '/^\(#\|\)KbdInteractiveAuthentication/s/^.*$/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config
#sed -i -e '/^\(#\|\)ChallengeResponseAuthentication/s/^.*$/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
#sed -i -e '/^\(#\|\)MaxAuthTries/s/^.*$/MaxAuthTries 2/' /etc/ssh/sshd_config
#sed -i -e '/^\(#\|\)AllowTcpForwarding/s/^.*$/AllowTcpForwarding no/' /etc/ssh/sshd_config
#sed -i -e '/^\(#\|\)X11Forwarding/s/^.*$/X11Forwarding no/' /etc/ssh/sshd_config
#sed -i -e '/^\(#\|\)AllowAgentForwarding/s/^.*$/AllowAgentForwarding no/' /etc/ssh/sshd_config
#sed -i -e '/^\(#\|\)AuthorizedKeysFile/s/^.*$/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config
#sed -i "$a AllowUsers ${NON_ROOT_USER}" /etc/ssh/sshd_config
#systemctl restart sshd

while ! passwd $NON_ROOT_USER
do
  echo "Error: password not set correctly - please try again"
done
