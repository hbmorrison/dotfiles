# Configuration.

CHOCO="/mnt/c/ProgramData/chocolatey/bin/choco.exe"

# Install chocolatey if it is not present.

if [ ! -r $CHOCO ]
then
  notice "installing Chocolatey with PowerShell"
  powershell.exe Start-Process -Verb runas -Wait powershell -ArgumentList "\"-NoExit Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))\""
  pass
fi
