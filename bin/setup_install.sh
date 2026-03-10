# Configuration.

# Get the name of the install environment file to use.

INSTALL_ENV=$1
shift

# Check that the environment file exists.

ENV_FILE="${ETC_DIR}/install_${INSTALL_ENV}.env"
if [ ! -f $ENV_FILE ]
then

  # Print a usage message listing all available install environments.

  AVAILABLE_ENVS="("
  for FILE in $ETC_DIR/install_*.env
  do
    NAME=$(basename -s .env $FILE | sed 's/^install_//')
    AVAILABLE_ENVS+="${NAME}|"
  done
  ARGS=$(echo $AVAILABLE_ENVS | sed 's/|$/)/')
  echo "Usage: setup ${SCRIPT} ${ARGS}"
  exit 1
fi

# Source the environment file.

source ${ENV_FILE} $*

# Check that the required variables are set.

if [ -z "${KEYRING_URL}" ]
then
  echo "Error: no KEYRING_URL set"
  exit 1
fi

if [ -z "${KEYRING_FILE}" ]
then
  echo "Error: no KEYRING_FILE set"
  exit 1
fi

if [ -z "${APT_SOURCE_URL}" ]
then
  echo "Error: no APT_SOURCE_URL set"
  exit 1
fi

if [ -z "${APT_SOURCE_FILE}" ]
then
  echo "Error: no APT_SOURCE_FILE set"
  exit 1
fi

if [ -z "${PACKAGES}" ]
then
  echo "Error: no PACKAGES set"
  exit 1
fi

if [ -z $BINARY ]
then
  echo "Error: no BINARY set"
  exit 1
fi

# Work out the locations and content of the keyring and source list.

KEYRING="/etc/apt/keyrings/${KEYRING_FILE}"
APT_SOURCE="/etc/apt/sources.list.d/${APT_SOURCE_FILE}"
APT_ARCH=$(dpkg --print-architecture)
APT_SOURCE_CONTENT="deb [arch=${APT_ARCH} signed-by=${KEYRING}] ${APT_SOURCE_URL}"
TMP_SOURCE=$(mktemp)

# Install dependencies.

if [ ! -z ${DEPENDENCIES:+z} ]
then
  notice "updating package lists"
  $SUDO apt update -y \
   &>/dev/null && pass || fail "could not update package lists"
  notice "installing dependencies"
  $SUDO apt install --no-install-recommends -y $DEPENDENCIES \
   &>/dev/null && pass || fail "could not install dependencies"
fi

# Install the keyring.

if [ ! -f $KEYRING ]
then
  notice "installing GPG keyring"
  curl -fsSL "${KEYRING_URL}" | $SUDO gpg --dearmor -o "${KEYRING}" \
   &>/dev/null && pass || fail "could not install GPG keyring"
fi

# Install the source list.

echo "${APT_SOURCE_CONTENT}" > $TMP_SOURCE
if ! diff $TMP_SOURCE $APT_SOURCE &>/dev/null
then
  notice "installing source list"
  cat $TMP_SOURCE | $SUDO tee $APT_SOURCE \
   &>/dev/null && pass || fail
  notice "updating package lists"
  $SUDO apt update -y &>/dev/null \
   && pass || fail "could not update package lists"
fi

# Install the packages.

if [ ! -f $BINARY ]
then
  notice "installing packages"
  $SUDO apt install --no-install-recommends -y $PACKAGES \
   &>/dev/null || fail "could not install packages"
  [ -f $BINARY ] && pass || fail "$BINARY not found after install"
fi

# Tidy up.

rm -f $TMP_SOURCE &>/dev/null

# Start service if one is specified.

if [ ! -z ${SERVICE:+z} ]
then
  if ! systemctl status $SERVICE &>/dev/null
  then
    notice "starting ${SERVICE} and enabling at boot"
    $SUDO systemctl enable --now $SERVICE \
     &>/dev/null && pass || fail
  fi
fi

# If an additional group is specified, add the current user to it.

if [ ! -z ${ADDITIONAL_GROUP:+z} ]
then
  if [ $(id -u) -gt 0 ]
  then
    if ! groups "${USER:-$USERNAME}" | grep " ${ADDITIONAL_GROUP}" &>/dev/null
    then
      notice "adding user ${USER:-$USERNAME} to ${ADDITIONAL_GROUP} group"
      $SUDO usermod -aG $ADDITIONAL_GROUP "${USER:-$USERNAME}" \
       &>/dev/null && pass || fail
    fi
  fi
fi
