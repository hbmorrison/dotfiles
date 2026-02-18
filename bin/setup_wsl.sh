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

# Install packages.

$SUDO apt update -y
$SUDO apt-get -y dist-upgrade
$SUDO apt-get install --no-install-recommends -y $SHELL_PACKAGES $NETWORK_PACKAGES

# Fix the WSL2 / Debian clock issue.

$SUDO hwclock -s

# Copy shell dotfiles and apply git config.

$BIN_DIR/setup shell
$BIN_DIR/setup gitconfig
