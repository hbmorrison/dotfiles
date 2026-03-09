# Repo configuration.

QMK_REPO="hbmorrison/qmk_firmware"
USERSPACE_REPO="hbmorrison/qmk_userspace"
UPSTREAM_REPO="qmk/qmk_firmware"
BRANCH="develop"

# Git configuration.

SSH_BASE="git@github.com:"
HTTP_BASE="https://github.com/"
QMK_URL="${SSH_BASE}${QMK_REPO}.git"
USERSPACE_URL="${SSH_BASE}${USERSPACE_REPO}.git"
UPSTREAM_URL="${HTTP_BASE}${UPSTREAM_REPO}.git"

# Directory configuration.

LOCAL_DIR="${HOME}/.local"
LOCAL_BIN_DIR="${LOCAL_DIR}/bin"
PROJECT_DIR="${HOME}/projects"
QMK_HOME="${LOCAL_DIR}/qmk_firmware"
USERSPACE_HOME="${PROJECT_DIR}/projects/qmk_userspace"
QMK_DIR=$(dirname $QMK_HOME)
USERSPACE_DIR=$(dirname $USERSPACE_HOME)

# Create the required directories.

[ -d $LOCAL_DIR ]     || mkdir -p $LOCAL_DIR
[ -d $PROJECT_DIR ]   || mkdir -p $PROJECT_DIR
[ -d $QMK_DIR ]       || mkdir -p $QMK_DIR
[ -d $USERSPACE_DIR ] || mkdir -p $USERSPACE_DIR

# Install QMK.

[ -x "${LOCAL_BIN_DIR}/qmk" ] || source $BIN_DIR/setup_pipx.sh qmk

# Checkout the QMK firmware repo manually.

if [ ! -d $QMK_HOME ]
then

  notice "cloning QMK firmware"
  /bin/git clone -b $QMK_BRANCH $QMK_URL $QMK_HOME \
   &>/dev/null && pass || fail

  notice "setting official QMK firmware repo as upstream"
  /bin/git -C $QMK_HOME remote add upstream $QMK_UPSTREAM_URL \
   &>/dev/null && pass || fail

  notice "initialising QMK firmware submodules"
  /bin/git -C $QMK_HOME submodule update --init --remote \
   &>/dev/null && pass || fail
else

  notice "synchronising QMK firmware submodules"
  /bin/git -C $QMK_HOME submodule sync \
   &>/dev/null && pass || fail

  notice "updating QMK firmware submodules from remotes"
  /bin/git -C $QMK_HOME submodule update --remote \
   &>/dev/null && pass || fail
fi

# Checkout the userspace repo manually.

if [ ! -d $USERSPACE_HOME ]
then
  notice "cloning userspace"
  /bin/git clone -b $USERSPACE_BRANCH $USERSPACE_URL $USERSPACE_HOME \
   &>/dev/null && pass || fail
  notice "initialising userspace submodules"
  /bin/git -C $USERSPACE_HOME submodule update --init --remote \
   &>/dev/null && pass || fail
else
  notice "synchronising userspace submodules"
  /bin/git -C $USERSPACE_HOME submodule sync \
   &>/dev/null && pass || fail
  notice "updating userspace submodules from remotes"
  /bin/git -C $USERSPACE_HOME submodule update --remote \
   &>/dev/null && pass || fail
fi

# Setup QMK.

if ! "${LOCAL_BIN_DIR}/qmk" doctor -n &>/dev/null
then
  "${LOCAL_BIN_DIR}/qmk" setup -H ${QMK_HOME} --baseurl ${SSH_BASE} -b ${BRANCH} ${QMK_REPO}
fi
