# Configuration.

SHELL_PACKAGES="bash-completion curl fzf git-flow gpg hiera-eyaml jq man-db \
 ripgrep shellcheck vim wget xclip zip"
NETWORK_PACKAGES="bind9-dnsutils inetutils-traceroute lsof ncat nmap socat \
 whois"
GPG_PACKAGES="gpg pinentry-tty scdaemon"

# Update and install required packages.

$SUDO apt update -y && $SUDO apt upgrade -y
$SUDO apt install -y --no-install-recommends $SHELL_PACKAGES $NETWORK_PACKAGES $GPG_PACKAGES

# Set up the dotfiles.

source $BIN_DIR/setup_shell.sh
