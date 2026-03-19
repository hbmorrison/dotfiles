# Configuration.

SHELL_PACKAGES="bash-completion curl expect fzf git-flow gpg hiera-eyaml jq \
  man-db ripgrep shellcheck vim wget xclip zip"
NETWORK_PACKAGES="bind9-dnsutils inetutils-traceroute lsof ncat nmap socat \
 whois"
GPG_PACKAGES="gpg pinentry-tty scdaemon"

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Update and install required packages.

updating "packages lists"
$SUDO apt update -y &>/dev/null && pass || fatal
upgrading "existing packages"
$SUDO apt upgrade -y &>/dev/null && pass || fatal
notice "upgrading required packages"
$SUDO apt install -y --no-install-recommends $SHELL_PACKAGES $NETWORK_PACKAGES $GPG_PACKAGES \
 &>/dev/null && pass || fatal

# Set up the dotfiles.

setup shell "$@"
