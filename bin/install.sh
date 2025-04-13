#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

SHELL_PACKAGES="bash-completion curl git-flow gpg vim wget xclip zip"
NETWORK_PACKAGES="bind9-dnsutils inetutils-traceroute lsof ncat nmap socat whois"
CHOCO="/c/ProgramData/chocolatey/bin/choco"
CHOCO_PACKAGES="7zip firacode nmap openjdk wincrypt-sshagent winscp"

# Work out whether to run commands using sudo.

SUDO=sudo

if [ `id -u` -eq 0 ]
then
  SUDO=""
fi

# Initialise submodules.

(cd "$BASE_DIR"; git submodule update --init --recursive)

# Work out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  MSYS*|MINGW64*)            SHELL_ENVIRONMENT="gitbash" ;;
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos" ;;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl" ;;
  *Debian*)                  SHELL_ENVIRONMENT="debian" ;;
  *Ubuntu*)                  SHELL_ENVIRONMENT="debian" ;;
  *Red\ Hat*)                SHELL_ENVIRONMENT="redhat" ;;
esac

# Find out the Windows home and program directories.

case $SHELL_ENVIRONMENT in
  wsl)
    PROGRAM_FILES="/mnt/c/Program Files"
    WINDOWS_HOME_DIR="/mnt/c/Users/${USER}"
    ;;
  gitbash)
    PROGRAM_FILES="/c/Program Files"
    WINDOWS_HOME_DIR="/c/Users/${USERNAME}"
    ;;
esac

# Update and install required packages.

case $SHELL_ENVIRONMENT in
  chromeos|wsl|debian)
    $SUDO apt-get update
    $SUDO apt-get -y dist-upgrade
    $SUDO apt-get install --no-install-recommends -y $SHELL_PACKAGES $NETWORK_PACKAGES
    ;;
  gitbash)
    if [ ! -r $CHOCO ]
    then
      powershell Start-Process -Verb runas -Wait powershell -ArgumentList "\"-NoExit Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))\""
    fi
    TO_BE_INSTALLED=""
    for PACKAGE in $CHOCO_PACKAGES
    do
      echo -n "Checking if $PACKAGE is installed ... "
      INSTALLED=`$CHOCO info -l -r $PACKAGE`
      if [ "${INSTALLED}" = "" ]
      then
        echo "no"
        TO_BE_INSTALLED="${PACKAGE} ${TO_BE_INSTALLED}"
      else
        echo "yes"
      fi
    done
    if [ "${TO_BE_INSTALLED}" != "" ]
    then
      echo "Installing ${TO_BE_INSTALLED}"
      powershell Start-Process -Verb runas -Wait powershell -ArgumentList "\"choco install -y $TO_BE_INSTALLED\""
    fi
    echo "Checking for updates"
    powershell Start-Process -Verb runas -Wait powershell -ArgumentList "\"choco upgrade all -y\""
    ;;
esac

# Set environment variables to use Windows OpenSSH.

case $SHELL_ENVIRONMENT in
  gitbash)
    echo "Setting environment variables for OpenSSH"
    PowerShell -Command "[System.Environment]::SetEnvironmentVariable('SSH_AUTH_SOCK','\\\\.\\pipe\\openssh-ssh-agent','User')"
    PowerShell -Command "[System.Environment]::SetEnvironmentVariable('GIT_SSH_COMMAND','C:/Windows/System32/OpenSSH/ssh.exe','User')"
    ;;
esac

# Install startup shortcuts on Windows.

case $SHELL_ENVIRONMENT in
  gitbash|wsl)
    APPDATA="${WINDOWS_HOME_DIR}/AppData"
    STARTUP_DIR="${APPDATA}/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
    BACKSLASHED_HOME_DIR="C:\\Users\\${USER:-$USERNAME}"
    BACKSLASHED_STARTUP_DIR="C:\\Users\\${USER:-$USERNAME}\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup"

    NOT_INSTALLED_SHORTCUTS=""
    for SHORTCUT_PS1 in $(ls -1 "${BASE_DIR}/etc/*.ps1")
    do
      SHORTCUT=$(basename $SHORTCUT_PS1 .ps1)
      echo -n "Checking if ${SHORTCUT} shortcut is installed ... "
      if [ ! -f "${STARTUP_DIR}/${SHORTCUT}.lnk" ]
      then
        echo "no"
        NOT_INSTALLED_SHORTCUTS="${NOT_INSTALLED_SHORTCUTS} ${SHORTCUT}"
      else
        echo "yes"
      fi
    done
    for SHORTCUT in $NOT_INSTALLED_SHORTCUTS
    do
      echo "Installing ${SHORTCUT} startup shortcut"
      cp -f "${BASE_DIR}/etc/${SHORTCUT_PS1}" $WINDOWS_HOME_DIR
      powershell.exe "Set-ExecutionPolicy Bypass -Scope Process -Force; ${BACKSLASHED_HOME_DIR}\\${SHORTCUT_PS1}"
      rm -f "${WINDOWS_HOME_DIR}/${SHORTCUT_PS1}"
    done
    ;;
esac

# Fix the WSL2 / Debian clock issue.

case $SHELL_ENVIRONMENT in
  wsl) $SUDO hwclock -s ;;
esac

# Run the dotfiles update.

source $BASE_DIR/bin/update.sh
