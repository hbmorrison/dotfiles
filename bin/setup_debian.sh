# Configuration.

SHELL_PACKAGES="bash-completion curl fzf git-flow gpg hiera-eyaml jq man-db \
 ripgrep vim wget xclip zip"
NETWORK_PACKAGES="bind9-dnsutils inetutils-traceroute lsof ncat nmap socat \
 whois"

# Update and install required packages.

$SUDO apt update -y && $SUDO apt upgrade -y
$SUDO apt install -y --no-install-recommends $SHELL_PACKAGES $NETWORK_PACKAGES

# Set up the dotfiles.

source $BIN_DIR/setup_shell.sh
