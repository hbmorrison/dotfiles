# Configuration.

SEARCH_DOMAINS="gerbil-koi.ts.net frogstar.party home"

# Work out whether to run commands using sudo.

SUDO=sudo

if [ `id -u` -eq 0 ]
then
  SUDO=""
fi

# Fix search domains.

echo -n "Adding search domains to resolv.conf... "

$SUDO sed -i.orig -e "/domain-name/s/^\\(#\\|\\)\\(supersede\\|prepend\\) domain-name .*$/prepend domain-name \"${SEARCH_DOMAINS} \";/" /etc/dhcp/dhclient.conf

echo "Done"

if ! diff /etc/dhcp/dhclient.conf /etc/dhcp/dhclient.conf.orig >& /dev/null
then
  echo -n "Restarting networking... "
  $SUDO systemctl restart networking
  echo "Done"
fi

# Run the debian setup script.

$BIN_DIR/setup debian
