# Configuration.

SHELL_PACKAGES="bash-completion curl fzf git-flow gpg hiera-eyaml jq man-db \
  ripgrep vim wget xclip zip"
NETWORK_PACKAGES="bind9-dnsutils inetutils-traceroute lsof ncat nmap socat whois"
CHOCO="/c/ProgramData/chocolatey/bin/choco"
CHOCO_INSTALLER="https://community.chocolatey.org/install.ps1"
CHOCO_PACKAGES="7zip autohotkey bitwarden firacode fzf nmap openjdk ripgrep \
  wincrypt-sshagent winscp"
SEARCH_DOMAINS="gerbil-koi.ts.net frogstar.party home"
WINDOWS_HOME_DIR="/mnt/c/Users/${USER}"
STARTUP_DIR="${WINDOWS_HOME_DIR}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
BACKSLASHED_HOME_DIR="C:\\Users\\${USER:-$USERNAME}"
BACKSLASHED_STARTUP_DIR="C:\\Users\\${USER:-$USERNAME}\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup"

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

$SUDO apt update -y
$SUDO apt-get -y dist-upgrade
$SUDO apt-get install --no-install-recommends -y $SHELL_PACKAGES $NETWORK_PACKAGES

# Set environment variables to use Windows OpenSSH.

echo -n "Setting environment variables for OpenSSH... "
powershell.exe -Command "[System.Environment]::SetEnvironmentVariable('SSH_AUTH_SOCK','\\\\.\\pipe\\openssh-ssh-agent','User')"
powershell.exe -Command "[System.Environment]::SetEnvironmentVariable('GIT_SSH_COMMAND','C:/Windows/System32/OpenSSH/ssh.exe','User')"
echo "Done"

# Install startup shortcuts.

NOT_INSTALLED_SHORTCUTS=""

for SHORTCUT_PS1 in $(ls -1 ${BASE_DIR}/etc/*.ps1)
do
  SHORTCUT=$(basename $SHORTCUT_PS1 .ps1)
  echo -n "Checking if ${SHORTCUT} shortcut is installed... "
  if [ ! -f "${STARTUP_DIR}/${SHORTCUT}.lnk" ]
  then
    echo "No"
    NOT_INSTALLED_SHORTCUTS="${NOT_INSTALLED_SHORTCUTS} ${SHORTCUT}"
  else
    echo "Yes"
  fi
done

for SHORTCUT in $NOT_INSTALLED_SHORTCUTS
do
  echo -n "Installing ${SHORTCUT} startup shortcut... "
  cp -f "${BASE_DIR}/etc/${SHORTCUT_PS1}" $WINDOWS_HOME_DIR
  powershell.exe "Set-ExecutionPolicy Bypass -Scope Process -Force; ${BACKSLASHED_HOME_DIR}\\${SHORTCUT_PS1}"
  rm -f "${WINDOWS_HOME_DIR}/${SHORTCUT_PS1}"
  echo "Done"
done

# Fix the WSL2 / Debian clock issue.

$SUDO hwclock -s

# Run the dotfiles and git scripts.

$BIN_DIR/setup shell
$BIN_DIR/setup gitconfig
