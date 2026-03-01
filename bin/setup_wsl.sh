# Fix the WSL2 / Debian clock issue.

$SUDO hwclock -s

# Run the debian setup script.

source $BIN_DIR/setup_debian.sh
