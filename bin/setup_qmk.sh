# Configuration.

QMK_UPSTREAM_URL="https://github.com/qmk/qmk_firmware.git"
QMK_URL="git@github.com:hbmorrison/qmk_firmware.git"
QMK_BRANCH="develop"
QMK_HOME="${HOME}/.local/qmk_firmware"
USERSPACE_URL="git@github.com:hbmorrison/qmk_userspace.git"
USERSPACE_BRANCH="develop"
USERSPACE_HOME="${HOME}/projects/qmk_userspace"

# Install QMK.

source $BIN_DIR/setup_pipx.sh qmk

# Checkout the QMK firmware repo manually.

QMK_DIR=$(dirname $QMK_HOME)
if [ ! -d $QMK_DIR ]
then
  mkdir -p $QMK_DIR
fi
if [ ! -d $QMK_HOME ]
then
  notice "cloning QMK firmware"
  /bin/git clone -b $QMK_BRANCH $QMK_URL $QMK_HOME \
   &>/dev/null && pass || fail
  notice "initialising QMK firmware submodules"
  /bin/git -C $QMK_HOME submodule update --init --remote \
   &>/dev/null && pass || fail
  notice "setting official QMK firmware repo as upstream"
  /bin/git -C $QMK_HOME remote add upstream $QMK_UPSTREAM_URL \
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

USERSPACE_DIR=$(dirname $USERSPACE_HOME)
if [ ! -d $USERSPACE_DIR ]
then
  mkdir -p $USERSPACE_DIR
fi
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

# Update the QMK firmware submodules.

exit
# Setup QMK.

if [ ! -d $QMK_HOME ]
then
  ~/.local/bin/qmk setup -H ${QMK_HOME} --baseurl ${QMK_BASEURL} -b ${QMK_BRANCH} ${QMK_REPO}
fi
