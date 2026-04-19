#!/bin/bash

set -o pipefail

# Configuration.

SEARCH_DOMAINS="gerbil-koi.ts.net home"
VPN_INTERFACE="VPN@Ed"

# Only run in WSL.

case $OS in
  wsl)

    # Define the powershell cmdlet for looking up DNS servers.

    DNS_SERVERS_CMDLET="Get-DnsClientServerAddress -AddressFamily IPv4 -ea 0"

    # Only proceed if the VPN connection exists.

    notice "Checking whether VPN connection ${VPN_INTERFACE} is defined"
    VPN_CONNECTION_CMDLET="Get-VpnConnection -AllUserConnection -Name ${VPN_INTERFACE}"
    if powershell.exe -Command "if (-not (${VPN_CONNECTION_CMDLET})) { Exit 1 }" &>/dev/null
    then
      yes

      # Change the DNS server lookup and search domains if the VPN is connected.

      notice "Checking whether VPN is connected"
      VPN_STATUS_CMD="${VPN_CONNECTION_CMDLET} | Select -expand ConnectionStatus"
      VPN_STATUS=$(powershell.exe -Command "${VPN_STATUS_CMD}" 2>/dev/null | tr -d '\r')
      if [ "${VPN_STATUS}" = "Connected" ]
      then
        yes

        # Only lookup DNS servers from the VPN connection.

        DNS_SERVERS_CMDLET="${DNS_SERVERS_CMDLET} -InterfaceAlias ${VPN_INTERFACE}"

        # Get search domains from Windows DNS settings.

        notice "Getting DNS search domains from Windows"
        DNS_SETTINGS_CMDLET="Get-DnsClientGlobalSetting -ea 0"
        DNS_SEARCH_CMD="(${DNS_SETTINGS_CMDLET} | Select -expand SuffixSearchList) -join ' '"
        SEARCH_DOMAINS=$(powershell.exe -Command "${DNS_SEARCH_CMD}" | tr -d '\r') \
         && pass || fail
      else
        no
      fi
    else
      no
    fi

    # Get the current DNS servers using powershell.

    notice "getting DNS servers from Windows"
    DNS_SERVERS_CMD="${DNS_SERVERS_CMDLET} | Select -expand ServerAddresses"
    DNS_SERVERS=$(powershell.exe -Command "${DNS_SERVERS_CMD}" | tr -d '\r') \
     && pass || fatal "no DNS servers found"

    # Make sure sudo has valid credentials before proceeding.

    setup_needs_sudo

    # Start with a fresh resolv.conf.

    notice "configuring resolv.conf"
    echo "# Run $BASE_DIR/setup dns to update." | $SUDO tee /etc/resolv.conf \
     &>/dev/null || fatal "could not overwrite resolv.conf"

    # add the DNS servers to resolv.conf.

    for SERVER in $DNS_SERVERS
    do
      echo "nameserver $SERVER" | $SUDO tee -a /etc/resolv.conf \
       &>/dev/null || fatal "could not append $SERVER to resolv.conf"
    done

    # Add the search domains to resolv.conf.

    echo "search $SEARCH_DOMAINS" | $SUDO tee -a /etc/resolv.conf \
     &>/dev/null || fatal "could not append search domains to resolv.conf"
    pass
 esac
