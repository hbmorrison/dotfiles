# Configuration.

SEARCH_DOMAINS="gerbil-koi.ts.net frogstar.party home"
PACKAGES="gpg gpg-agent pcscd pcsc-tools scdaemon yubikey-manager"

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Update and install required packages.

notice "installing required packages for yubikey"
$SUDO apt update -y &>/dev/null \
 && $SUDO apt install -y --no-install-recommends $PACKAGES &>/dev/null \
 && pass || fail

# Configure access to yubikey smartcard interface.

notice "Copying yubikey polkit rules"
$SUDO cp -f $ETC_DIR/chromeos/99-yubikey-polkit.rules /etc/polkit-1/rules.d/99-yubikey.rules \
 &>/dev/null && pass || fail
notice "Copying yubikey udev rules"
$SUDO cp -f $ETC_DIR/chromeos/99-yubikey-udev.rules /etc/udev/rules.d/99-yubikey.rules \
 &>/dev/null && pass || fail
notice "Reloading udev rules"
$SUDO udevadm control --reload &>/dev/null && pass || fail
notice "Enabling pcscd"
$SUDO systemctl enable --now pcscd.socket &>/dev/null && pass || fail

# Fix search domains.

notice "adding search domains to resolv.conf"
$SUDO sed -i.orig -e "/domain-name/s/^\\(#\\|\\)\\(supersede\\|prepend\\) domain-name .*$/prepend domain-name \"${SEARCH_DOMAINS} \";/" /etc/dhcp/dhclient.conf \
 && pass || fail

if ! diff /etc/dhcp/dhclient.conf /etc/dhcp/dhclient.conf.orig &> /dev/null
then
  if [ ! -z ${SUDO} ]
  then
    if ! sudo -n /bin/true 2>/dev/null
    then
      sudo -v || fatal "could not authenticate with sudo"
    fi
  fi
  notice "restarting networking"
  $SUDO systemctl restart networking &>/dev/null && pass || fail
fi

# Install required packages.

setup debian
setup udisks

# Customise the shell environment.

setup shell
setup git
setup ssh
setup vim
