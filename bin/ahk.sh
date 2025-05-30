#!/bin/bash

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

STARTUP_LOCATION="Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
AUTO_HOTKEY_SCRIPTS="bitwarden.ahk pmp.ahk"

# Figure out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  *microsoft-standard-WSL2*)
    SHELL_ENVIRONMENT="wsl"
    PROGRAM_FILES="/mnt/c/Program Files"
    WINDOWS_HOME_DIR="/mnt/c/Users/${USER}"
    APPDATA="/mnt/c/Users/${USER}/AppData"
    ;;
  CYGWIN_NT*|MSYS*|MINGW64*)
    SHELL_ENVIRONMENT="gitbash"
    PROGRAM_FILES="/c/Program Files"
    WINDOWS_HOME_DIR="/c/Users/${USERNAME}"
    APPDATA="${HOME}/AppData"
    ;;
  *)
    echo "Error: Unknown architecture / distribution in /proc/version"
    exit 1
    ;;
esac

# Work out locations of various system files and programs.

STARTUP_DIR="${APPDATA}/${STARTUP_LOCATION}"
BACKSLASHED_STARTUP_DIR="C:\\Users\\${USER:-$USERNAME}\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup"
AUTO_HOTKEY="${PROGRAM_FILES}/AutoHotkey/AutoHotkey.exe"

# Copy AHK scripts.

case $SHELL_ENVIRONMENT in
  gitbash|wsl)
    echo "Stopping all AutoHotkey scripts"
    if [ "${SHELL_ENVIRONMENT}" == "gitbash" ]
    then
      taskkill.exe //im autohotkey.exe &>/dev/null
    else
      taskkill.exe /im autohotkey.exe &>/dev/null
    fi
    for AUTO_HOTKEY_SCRIPT in $AUTO_HOTKEY_SCRIPTS
    do
      if [ ! -r "${STARTUP_DIR}/${AUTO_HOTKEY_SCRIPT}" ]
      then
        echo "Installing ${AUTO_HOTKEY_SCRIPT}"
      else
        echo "Updating ${AUTO_HOTKEY_SCRIPT}"
      fi
      cp -f "${BASE_DIR}/etc/${AUTO_HOTKEY_SCRIPT}" "${STARTUP_DIR}/${AUTO_HOTKEY_SCRIPT}"
      echo "Starting ${AUTO_HOTKEY_SCRIPT}"
      "${AUTO_HOTKEY}" "${BACKSLASHED_STARTUP_DIR}\\${AUTO_HOTKEY_SCRIPT}" &>/dev/null & disown
    done
    ;;
esac
