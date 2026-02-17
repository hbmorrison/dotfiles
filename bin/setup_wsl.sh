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

# Override wsl.conf to enable systemd.

echo -n "Checking if WSL is configured correctly... "
if ! diff $BASE_DIR/etc/wsl.conf /etc/wsl.conf >& /dev/null
then
  echo "No"
  $SUDO cp $BASE_DIR/etc/wsl.conf /etc/wsl.conf
  echo
  echo " 1. Hit Enter to restart WSL"
  echo " 2. Accept the UAC for Powershell"
  echo " 3. Open the Terminal app again"
  echo " 4. Re-run ${SETUP_SCRIPT} ${SUB_SCRIPT}"
  echo
  read -s
  echo "Restarting..."
  powershell.exe Start-Process -Verb runas -Wait powershell -ArgumentList "\"wsl --shutdown\""
else
  echo "Yes"
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
