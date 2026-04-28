# Configuration.

PACKAGES="gpg gpg-agent pcscd pcsc-tools scdaemon yubikey-manager"

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Update and install yubikey packages.

notice "installing required packages for yubikey"
$SUDO apt update -y &>/dev/null \
 && $SUDO apt install -y --no-install-recommends $PACKAGES &>/dev/null \
 && pass || fail

# Configure access to yubikey smartcard interface.

notice "Copying yubikey polkit rules"
$SUDO cp -f $ETC_DIR/debian/99-yubikey-polkit.rules /etc/polkit-1/rules.d/99-yubikey.rules \
 &>/dev/null && pass || fail
notice "Copying yubikey udev rules"
$SUDO cp -f $ETC_DIR/debian/99-yubikey-udev.rules /etc/udev/rules.d/99-yubikey.rules \
 &>/dev/null && pass || fail
notice "Reloading udev rules"
$SUDO udevadm control --reload &>/dev/null && pass || fail
notice "Enabling pcscd"
$SUDO systemctl enable --now pcscd.socket &>/dev/null && pass || fail
