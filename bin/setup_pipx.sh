# Configuration.

# Work out the name of the environment file.

INSTALL_ENV=$1
shift

ENV_FILE="${ETC_DIR}/pipx_${INSTALL_ENV}.env"

if [ ! -f $ENV_FILE ]
then
  AVAILABLE_ENVS="("
  for FILE in $ETC_DIR/pipx_*.env
  do
    NAME=$(basename -s .env $FILE | sed 's/^pipx_//')
    AVAILABLE_ENVS+="${NAME}|"
  done
  ARGS=$(echo $AVAILABLE_ENVS | sed 's/|$/)/')
  echo "Usage: ${SETUP_SCRIPT} ${SUB_SCRIPT} ${ARGS}"
  exit 1
fi

# Source the environment file.

source ${ENV_FILE}

# Check that the required variables are set.

if [ -z "${PACKAGES}" ]
then
  echo "Error: no PACKAGES set"
  exit 1
fi

# Work out whether to run commands using sudo.

SUDO=sudo

if [ `id -u` -eq 0 ]
then
  SUDO=""
fi

# Install dependencies.

if [ ! -z ${DEPENDENCIES:+z} ]
then

  echo -n "Updating package lists... "

  if $SUDO apt update -y &>/dev/null
  then
    echo "Done"
  else
    echo
    echo "Error: run $SUDO apt update -y"
    exit 1
  fi

  echo -n "Installing dependencies... "

  if $SUDO apt install --no-install-recommends -y $DEPENDENCIES &>/dev/null
  then
    echo "Done"
  else
    echo
    echo "Error: run $SUDO apt install --no-install-recommends -y $DEPENDENCIES"
    exit 1
  fi

fi

# Install.

for PACKAGE in $PACKAGES
do
  if pipx list --short | grep "^${PACKAGE} " &>/dev/null
  then
    echo -n "Upgrading ${PACKAGE}... "
    if pipx upgrade $PACKAGE &>/dev/null
    then
      echo "Done"
    else
      echo
      echo "Error: run pipx upgrade $PACKAGE"
      exit 1
    fi
  else
    echo -n "Installing ${PACKAGE}... "
    if pipx install $PACKAGE &>/dev/null
    then
      echo "Done"
    else
      echo
      echo "Error: run pipx install $PACKAGE"
      exit 1
    fi
  fi
done
