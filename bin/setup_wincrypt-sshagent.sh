# Configuration.

WINDOWS_HOME_DIR="/mnt/c/Users/${USER}"
STARTUP_DIR="${WINDOWS_HOME_DIR}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
BACKSLASHED_HOME_DIR="C:\\Users\\${USER:-$USERNAME}"

# Make sure that chocolatey is installed.

source $BIN_DIR/setup_choco.sh

# Install wincrypt-sshagent.

notice "Checking if wincrypt-sshagent is installed"
INSTALLED=$($CHOCO info -l -r wincrypt-sshagent)
if [ -z ${INSTALLED:+z} ]
then
  echo "No"
  notice "Installing wincrypt-sshagent with PowerShell (accept UAC prompt)"
  sleep 2
  powershell.exe Start-Process -Verb runas -Wait powershell -ArgumentList "\"choco install -y wincrypt-sshagent\""
  echo "Done"
else
  echo "Yes"
  notice "Checking for updates with PowerShell (accept UAC prompt)"
  sleep 2
  powershell.exe Start-Process -Verb runas -Wait powershell -ArgumentList "\"choco upgrade wincrypt-sshagent -y\""
  echo "Done"
fi

# Set environment variables for Windows OpenSSH to use wincrypt-sshagent.

notice "setting environment variables for OpenSSH (takes a minute)"
powershell.exe -Command "[System.Environment]::SetEnvironmentVariable('SSH_AUTH_SOCK','\\\\.\\pipe\\openssh-ssh-agent','User')"
powershell.exe -Command "[System.Environment]::SetEnvironmentVariable('GIT_SSH_COMMAND','C:/Windows/System32/OpenSSH/ssh.exe','User')"
notice_ok

# Install wincrypt-sshagent startup shortcut.

notice "checking if wincrypt-sshagent startup shortcut is installed"
if [ -f "${STARTUP_DIR}/WinCryptSSHAgent.lnk" ]
then
  notice_yes
else
  notice_no
  notice "installing wincrypt-sshagent startup shortcut"
  cp -f "${BASE_DIR}/etc/wincrypt-sshagent.ps1" $WINDOWS_HOME_DIR
  powershell.exe "Set-ExecutionPolicy Bypass -Scope Process -Force; ${BACKSLASHED_HOME_DIR}\\wincrypt-sshagent.ps1"
  rm -f "${WINDOWS_HOME_DIR}/wincrypt-sshagent.ps1"
  notice_ok
fi
