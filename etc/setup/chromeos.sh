# Configuration.

CHROMEOS_PACKAGES="gpg-agent pinentry-tty"
SEARCH_DOMAINS="gerbil-koi.ts.net frogstar.party home"

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Update and install required packages.

notice "installing required packages for chromeos"
$SUDO apt update -y &>/dev/null \
 && $SUDO apt install -y --no-install-recommends $CHROMEOS_PACKAGES &>/dev/null \
 && pass || fail

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

# Install required packages and configure udisks and yubikey.

setup packages "$@"
setup udisks "$@"
setup yubikey "$@"

# Set up the shell.

setup shell "$@"

# Customise tools.

setup git "$@"
setup ssh "$@"
setup vim "$@"
