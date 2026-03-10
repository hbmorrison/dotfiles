#!/bin/bash

# Configuration.

PROGRAM_DATA_DIR="/mnt/c/ProgramData"
APPDATA_DIR="/mnt/c/Users/${USER}/AppData"
STARTUP_SUB_DIR="Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
STARTUP_DIR="${APPDATA_DIR}/${STARTUP_SUB_DIR}"
BACKSLASHED_STARTUP_DIR=$(sed 's/\//\\/g' <<< ${STARTUP_DIR/\/mnt\/c/C:})
AUTO_HOTKEY="${PROGRAM_DATA_DIR}/chocolatey/bin/AutoHotKey.exe"

# Make sure that chocolatey is installed.

source $BIN_DIR/setup_choco.sh

# Install autohotkey.

notice "Checking if AutoHotKey is installed"
INSTALLED=$($CHOCO info -l -r autohotkey)
if [ -z ${INSTALLED:+z} ]
then
  notice_no
  notice "installing AutoHotKey with PowerShell (accept UAC prompt)"
  sleep 2
  powershell.exe Start-Process -Verb runas -Wait powershell -ArgumentList "\"choco install -y autohotkey\""
  pass
else
  notice_yes
  notice "checking for updates with PowerShell (accept UAC prompt)"
  sleep 2
  powershell.exe Start-Process -Verb runas -Wait powershell -ArgumentList "\"choco upgrade autohotkey -y\""
  pass
fi

# Kill any running AHK processes.

notice "stopping all AutoHotkey scripts"
taskkill.exe /im autohotkey.exe &>/dev/null
pass

# Copy the AutoHotKey scripts.

for SCRIPT_PATH in $(ls -1 ${ETC_DIR}/*.ahk)
do
  AUTO_HOTKEY_SCRIPT=$(basename $SCRIPT_PATH .ahk)
  if [ ! -r "${STARTUP_DIR}/${AUTO_HOTKEY_SCRIPT}.ahk" ]
  then
    notice "installing ${AUTO_HOTKEY_SCRIPT} AutoHotKey script"
  else
    notice "updating ${AUTO_HOTKEY_SCRIPT} AutoHotKey script"
  fi
  cp -f "${ETC_DIR}/${AUTO_HOTKEY_SCRIPT}.ahk" "${STARTUP_DIR}/${AUTO_HOTKEY_SCRIPT}.ahk"
  pass

  # Start AHK running each script after is is copied.

  notice "starting ${AUTO_HOTKEY_SCRIPT} AutoHotKey script"
  "${AUTO_HOTKEY}" "${BACKSLASHED_STARTUP_DIR}\\${AUTO_HOTKEY_SCRIPT}.ahk" &>/dev/null & disown
  pass
done
