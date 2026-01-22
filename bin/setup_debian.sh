# Configuration.

SHELL_PACKAGES="bash-completion curl fzf git-flow gpg hiera-eyaml jq man-db \
  ripgrep vim wget xclip zip"
NETWORK_PACKAGES="bind9-dnsutils inetutils-traceroute lsof ncat nmap socat whois"

# Work out whether to run commands using sudo.

SUDO=sudo

if [ `id -u` -eq 0 ]
then
  SUDO=""
fi

# Update and install required packages.

$SUDO apt update -y
$SUDO apt -y dist-upgrade
$SUDO apt install --no-install-recommends -y $SHELL_PACKAGES $NETWORK_PACKAGES

# Run the dotfiles and git scripts.

$BIN_DIR/setup shell
$BIN_DIR/setup gitconfig
