# Install required packages.

setup debian/packages
setup debian/yubikey
setup debian/pamu2f

# Install required apps.

setup install 1password

# Install my GPG public keys.

setup debian/my_public_keys

# Customise the shell environment.

setup shell
