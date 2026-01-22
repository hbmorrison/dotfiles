# Configuration.

PROGRAM_DATA_DIR="/mnt/c/ProgramData"
APPDATA_DIR="/mnt/c/Users/${USER}/AppData"
STARTUP_SUB_DIR="Roaming/Microsoft/Windows/Start Menu/Programs/Startup"
STARTUP_DIR="${APPDATA_DIR}/${STARTUP_SUB_DIR}"
BACKSLASHED_STARTUP_DIR=$(sed 's/\//\\/g' <<< ${STARTUP_DIR/\/mnt\/c/C:})
AUTO_HOTKEY="${PROGRAM_DATA_DIR}/chocolatey/bin/AutoHotKey.exe"

# Copy AutoHotKey scripts.

echo "Stopping all AutoHotkey scripts..."
taskkill.exe /im autohotkey.exe &>/dev/null

for SCRIPT_PATH in $(ls -1 ${ETC_DIR}/*.ahk)
do
  AUTO_HOTKEY_SCRIPT=$(basename $SCRIPT_PATH .ahk)
  if [ ! -r "${STARTUP_DIR}/${AUTO_HOTKEY_SCRIPT}.ahk" ]
  then
    echo "Installing ${AUTO_HOTKEY_SCRIPT} AutoHotKey script..."
  else
    echo "Updating ${AUTO_HOTKEY_SCRIPT} AutoHotKey script..."
  fi
  cp -f "${ETC_DIR}/${AUTO_HOTKEY_SCRIPT}.ahk" "${STARTUP_DIR}/${AUTO_HOTKEY_SCRIPT}.ahk"
  echo "Starting ${AUTO_HOTKEY_SCRIPT} AutoHotKey script..."
  "${AUTO_HOTKEY}" "${BACKSLASHED_STARTUP_DIR}\\${AUTO_HOTKEY_SCRIPT}.ahk" &>/dev/null & disown
done
