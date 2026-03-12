# Configuration.

SEARCH_DOMAINS="gerbil-koi.ts.net frogstar.party home"

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
      sudo -v || fail "could not authenticate with sudo"
    fi
  fi
  notice "Restarting networking"
  $SUDO systemctl restart networking &>/dev/null && pass || fail
fi

# Run the debian setup script.

source $BIN_DIR/setup_debian.sh
