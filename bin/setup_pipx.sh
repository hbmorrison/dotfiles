# Get the name of the pipx environment file to run.

INSTALL_ENV=$1
shift

# Check that the environment file exists.

ENV_FILE="${ETC_DIR}/pipx_${INSTALL_ENV}.env"
if [ ! -f $ENV_FILE ]
then

  # Print a usage message listing all available pipx environments.

  AVAILABLE_ENVS="("
  for FILE in $ETC_DIR/pipx_*.env
  do
    NAME=$(basename -s .env $FILE | sed 's/^pipx_//')
    AVAILABLE_ENVS+="${NAME}|"
  done
  ARGS=$(echo $AVAILABLE_ENVS | sed 's/|$/)/')
  usage "${SCRIPT} ${ARGS}"
  exit 1
fi

# Source the environment file.

source ${ENV_FILE} "$@"

# Check that the required variables are set.

[ -z "${PACKAGES}" ] && fatal "no PACKAGES set"

# Make sure sudo has valid credentials before starting.

if [ ! -z ${SUDO} ]
then
  if ! sudo -n /bin/true 2>/dev/null
  then
    sudo -v || fatal "could not authenticate with sudo"
  fi
fi

# Install dependencies.

if [ ! -z ${DEPENDENCIES:+z} ]
then
  updating "package lists"
  $SUDO apt update -y &>/dev/null && pass || fatal
  installing "dependencies"
  $SUDO apt install --no-install-recommends -y $DEPENDENCIES \
   &>/dev/null && pass || fatal
fi

# Install.

for PACKAGE in $PACKAGES
do
  if pipx list --short | grep "^${PACKAGE} " &>/dev/null
  then
    upgrading "pipx package ${PACKAGE}"
    pipx upgrade $PACKAGE &>/dev/null && pass || fatal
  else
    installing "pipx package ${PACKAGE}"
    pipx install $PACKAGE &>/dev/null && pass || fatal
  fi
done
