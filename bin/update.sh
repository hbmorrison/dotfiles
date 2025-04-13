#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Initialise submodules.

(cd "$BASE_DIR"; git submodule update --init --recursive)

# Work out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  MSYS*|MINGW64*)            SHELL_ENVIRONMENT="gitbash" ;;
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos" ;;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl" ;;
  *Debian*)                  SHELL_ENVIRONMENT="debian" ;;
  *Ubuntu*)                  SHELL_ENVIRONMENT="debian" ;;
  *Red\ Hat*)                SHELL_ENVIRONMENT="redhat" ;;
esac

# Create any directories that are needed.

for DIR in $(cd $BASE_DIR; find . -type d -not -path "."  | sed  's#^./##')
do

  case $DIR in

    # Ignore the git directory.

    \.git) ;;
    \.git/*) ;;

    # Ignore submodules.

    vim) ;;
    vim/*) ;;
    vim-pathogen) ;;
    vim-pathogen/*) ;;

    # Ignore directories used for special cases below.

    etc) ;;
    etc/*) ;;

    # Create other directories under the home directory.

    *)
      if [ ! -d "${HOME}/.${DIR}" ]
      then
        mkdir "${HOME}/.${DIR}"
      fi
      ;;

  esac

done

# Make sure these directories are secure.

chmod go-rwx $HOME/.ssh $HOME/.eyaml

# Copy the dotfiles.

for ITEM in $(cd $BASE_DIR; find . -type f  | sed  's#^./##')
do

  case $ITEM in

    # Ignore repo files.

    \.git/*) ;;
    \.git*) ;;

    # Ignore submodules.

    vim/*) ;;
    vim-pathogen/*) ;;

    # Ignore scripts and files that are dealt with as special cases.

    *.sh) ;;
    etc/*) ;;

    # Copy everything else.

    *) cp $BASE_DIR/$ITEM "$HOME/.${ITEM}" ;;

  esac

done

# Check that the authorized_keys file exists.

AUTHORIZED_KEYS="$HOME/.ssh/authorized_keys"

if [ ! -f $AUTHORIZED_KEYS ]
then
  touch $AUTHORIZED_KEYS
fi

# Go through each ssh key and add it to authorized_keys if not present.

while read -r TYPE KEY COMMENT
do
  if ! grep "${KEY}" $AUTHORIZED_KEYS > /dev/null 2>&1
  then
    echo "${COMMENT} added to authorized keys"
    echo "${TYPE} ${KEY} ${COMMENT}" >> $AUTHORIZED_KEYS
  fi
done < "${BASE_DIR}/etc/authorized_keys"

# Copy the gitconfig file, extracting and replacing the user name and email.

if [ -r "${HOME}/.gitconfig" ]
then

  TEMP_USER_SECTION=`mktemp`
  awk -f - $HOME/.gitconfig > $TEMP_USER_SECTION <<EXTRACT_USER_SECTION
BEGIN { USER_SECTION = 0; }
/^\[/ { if ( USER_SECTION == 1 ) { USER_SECTION = 0; } }
/^\[user\]/ { USER_SECTION = 1; }
{ if ( USER_SECTION == 1 ) { print; } }
EXTRACT_USER_SECTION

  cp $BASE_DIR/etc/gitconfig $HOME/.gitconfig
  cat $TEMP_USER_SECTION >> $HOME/.gitconfig

  rm -f $TEMP_USER_SECTION

else

  cp $BASE_DIR/etc/gitconfig $HOME/.gitconfig

fi

# Configure Vim.

if [ -d $HOME/.vim ]
then
  if [ -d $HOME/.vim.old ]
  then
    rm -rf "${HOME}/.vim.old" 2> /dev/null
  fi
  mv "${HOME}/.vim" "${HOME}/.vim.old" 2> /dev/null
fi

cp -r "${BASE_DIR}/vim" "${HOME}/.vim"
mkdir -p "${HOME}/.vim/autoload"
rm -f "${HOME}/.vim/autoload/pathogen.vim" 2> /dev/null
cp -f "${BASE_DIR}/vim-pathogen/autoload/pathogen.vim" "${HOME}/.vim/autoload/pathogen.vim"

# Copy the necessary files to the Windows roaming profile if one is being used.

if [ "${SHELL_ENVIRONMENT}" = "gitbash" ]
then

  ROAMING_PROFILE_FILES=".bash_profile .minttyrc"
  PROFILEDRIVE=`echo $USERPROFILE | cut -d'\' -f1`

  if [ "$PROFILEDRIVE" != "$HOMEDRIVE" ]
  then

    ROAMING_HOME=`cygpath $HOMEDRIVE$HOMEPATH`
    export HOME=`cygpath $USERPROFILE`

    # Make sure the minimum set of files appear in the roaming home directory.

    for FILE in $ROAMING_PROFILE_FILES
    do
      cp $HOME/$FILE $ROAMING_HOME/$FILE
    done

    # Make a copy of the SSH directory in the roaming home directory.

    mkdir -p $ROAMING_HOME/.ssh
    cp -f $HOME/.ssh/config $ROAMING_HOME/.ssh
    chmod go-rwx $ROAMING_HOME/.ssh

  fi

fi
