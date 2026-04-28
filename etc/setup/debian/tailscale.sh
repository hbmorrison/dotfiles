# Configuration.

TIMESTAMP=$(date '+%Y%M%dT%H%M')
TAILSCALE_ARGS="--accept-routes --accept-risk=all"

# Install and configure tailscale.

systemctl status tailscaled.service &>/dev/null
if [ $? -eq 4 ]
then
  setup install tailscale
  tailscale set $TAILSCALE_ARGS
fi

# Secure tailscaled.

if [ -f /etc/default/tailscaled ]
then
  notice "copying backup of Tailscale config"
  cp /etc/default/tailscaled /etc/default/tailscaled.$TIMESTAMP && pass || fatal
  notice "adding extra flags to Tailscale config"
  sed -i -e '/^FLAGS=/s/""/"--no-logs-no-support"/' /etc/default/tailscaled && pass || fail
  if diff /etc/default/tailscaled /etc/default/tailscaled.$TIMESTAMP &>/dev/null
  then
    notice "restarting tailscaled"
    systemctl restart tailscaled.service && pass || fail
  fi
fi
