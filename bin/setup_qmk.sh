# Fail if any command in a pipe fails.

set -o pipefail

# Repo configuration.

QMK_REPO="hbmorrison/qmk_firmware"
QMK_UPSTREAM_REPO="qmk/qmk_firmware"
QMK_BRANCH="develop"
USERSPACE_REPO="hbmorrison/qmk_userspace"
USERSPACE_BRANCH="develop"

# Installer configuration.

QMK_INSTALLER="${ETC_DIR}/qmk_installer_20260312.sh"
QMK_INSTALLER_ARGS="--skip-udev-rules"
QMK_LOG=$(mktemp -q --suffix=.log)

# Git configuration.

SSH_BASE="git@github.com:"
HTTPS_BASE="https://github.com/"
QMK_URL="${SSH_BASE}${QMK_REPO}.git"
QMK_UPSTREAM_URL="${HTTPS_BASE}${QMK_UPSTREAM_REPO}.git"
USERSPACE_URL="${SSH_BASE}${USERSPACE_REPO}.git"

# Directory configuration.

LOCAL_DIR="${HOME}/.local"
LOCAL_BIN_DIR="${LOCAL_DIR}/bin"
QMK_HOME="${LOCAL_DIR}/share/qmk_firmware"
QMK_DIR=$(dirname $QMK_HOME)
PROJECT_DIR="${HOME}/projects"
USERSPACE_HOME="${PROJECT_DIR}/qmk_userspace"
USERSPACE_DIR=$(dirname $USERSPACE_HOME)

# Create the required directories.

[ -d $LOCAL_DIR ]     || mkdir -p $LOCAL_DIR
[ -d $PROJECT_DIR ]   || mkdir -p $PROJECT_DIR
[ -d $QMK_DIR ]       || mkdir -p $QMK_DIR
[ -d $USERSPACE_DIR ] || mkdir -p $USERSPACE_DIR

# Make sure sudo has valid credentials before starting.

if [ ! -z ${SUDO} ]
then
  sudo -v &>/dev/null || fail "could not authenticate with sudo"
fi

# Install QMK.

[ -f $QMK_INSTALLER ] || fail "Could not find QMK installer script"

notice "installing QMK"
/bin/sh $QMK_INSTALLER $QMK_INSTALLER_ARGS 2>/dev/null | tee -a $QMK_LOG \
 &>/dev/null && pass || fail "could not install QMK"

# Checkout the QMK firmware repo manually.

if [ ! -d $QMK_HOME ]
then

  # Clone the QMK firmware repo if it does not exist locally. Set upstream and
  # initialise the submodules.

  notice "cloning QMK firmware repo"
  /bin/git clone -b $QMK_BRANCH $QMK_URL $QMK_HOME \
   &>/dev/null && pass || fail

  notice "setting official QMK firmware repo as upstream"
  /bin/git -C $QMK_HOME remote add upstream $QMK_UPSTREAM_URL \
   &>/dev/null && pass || fail

  notice "initialising QMK firmware repo submodules"
  /bin/git -C $QMK_HOME submodule update --init --recursive --remote \
   &>/dev/null && pass || fail
else

  # If the local QMK firmware repo is present, sync the submodules with origin
  # and update them.

  notice "synchronising QMK firmware repo submodules"
  /bin/git -C $QMK_HOME submodule sync \
   &>/dev/null && pass || fail

  notice "updating QMK firmware repo submodules from remotes"
  /bin/git -C $QMK_HOME submodule update --recursive --remote \
   &>/dev/null && pass || fail
fi

# Checkout the userspace repo manually.

if [ ! -d $USERSPACE_HOME ]
then

  # Clone the userspace repo if it does not exist locally then initialise the
  # submodules.

  notice "cloning QMK userspace repo"
  /bin/git clone -b $USERSPACE_BRANCH $USERSPACE_URL $USERSPACE_HOME \
   &>/dev/null && pass || fail

  notice "initialising QMK userspace repo submodules"
  /bin/git -C $USERSPACE_HOME submodule update --init --remote \
   &>/dev/null && pass || fail
else

  # If the local userspace repo is present, sync the submodules with origin and
  # update them.

  notice "synchronising QMK userspace repo submodules"
  /bin/git -C $USERSPACE_HOME submodule sync \
   &>/dev/null && pass || fail

  notice "updating QMK userspace repo submodules from remotes"
  /bin/git -C $USERSPACE_HOME submodule update --remote \
   &>/dev/null && pass || fail
fi

# Setup QMK.

notice "setting up QMK"
/bin/expect -f "${ETC_DIR}/qmk_setup.exp" ${QMK_HOME} ${SSH_BASE} ${QMK_BRANCH} ${QMK_REPO} \
 | tee -a $QMK_LOG &>/dev/null && pass || fail "could not run qmk setup"

# Mention the QMK output log.

echo "Log of QMK install and setup available in ${QMK_LOG}"
