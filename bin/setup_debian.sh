# Configuration.

SHELL_PACKAGES="bash-completion curl expect fzf git-flow gpg hiera-eyaml jq \
  man-db ripgrep shellcheck vim wget xclip zip"
NETWORK_PACKAGES="bind9-dnsutils inetutils-traceroute lsof ncat nmap socat \
 whois"
GPG_PACKAGES="gpg pinentry-tty scdaemon"

# Make sure sudo has valid credentials before starting.

if [ ! -z ${SUDO} ]
then
  if ! sudo -n /bin/true 2>/dev/null
  then
    sudo -v || fatal "could not authenticate with sudo"
  fi
fi

# Update and install required packages.

updating "packages lists"
$SUDO apt update -y &>/dev/null && pass || fatal
upgrading "existing packages"
$SUDO apt upgrade -y &>/dev/null && pass || fatal
notice "upgrading required packages"
$SUDO apt install -y --no-install-recommends $SHELL_PACKAGES $NETWORK_PACKAGES $GPG_PACKAGES \
 &>/dev/null && pass || fatal

# Set up the dotfiles.

source $BIN_DIR/setup_shell.sh
