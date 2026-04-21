# Configuration.

DEBIAN_PACKAGES="bash-completion bind9-dnsutils curl expect fzf git-flow \
 hiera-eyaml inetutils-traceroute jq lsof man-db ncat nmap ripgrep shellcheck \
 socat vim wget whois xclip zip"

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Upgrade and install required packages for debian.

notice "upgrading debian"
$SUDO apt update -y &>/dev/null \
 && $SUDO apt upgrade -y &>/dev/null \
 && pass || fatal

# Install required packages.

notice "installing required packages for debian"
$SUDO apt install -y --no-install-recommends $DEBIAN_PACKAGES &>/dev/null \
 && pass || fail
