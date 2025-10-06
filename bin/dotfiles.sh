#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)

# Configuration.

VIM_PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/refs/heads/master/plug.vim"
ROAMING_PROFILE_FILES=".bash_profile .minttyrc"

# Work out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  MSYS*|MINGW64*)            SHELL_ENVIRONMENT="gitbash" ;;
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos" ;;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="wsl" ;;
  *Debian*)                  SHELL_ENVIRONMENT="debian" ;;
  *Ubuntu*)                  SHELL_ENVIRONMENT="debian" ;;
  *Red\ Hat*)                SHELL_ENVIRONMENT="redhat" ;;
esac

# Set the home directory correctly in gitbash.

if [ "${SHELL_ENVIRONMENT}" = "gitbash" ]
then
  CYG_USERPROFILE=`cygpath $USERPROFILE`
  if [ "$HOME" != "$CYG_USERPROFILE" ]
  then
    export HOME=$CYG_USERPROFILE
    cd
  fi
fi

# Backup vim directory.

if [ -d $HOME/.vim ]
then
  if [ -d $HOME/.vim.old ]
  then
    rm -rf "${HOME}/.vim.old" 2> /dev/null
  fi
  mv "${HOME}/.vim" "${HOME}/.vim.old" 2> /dev/null
fi

# Create any directories that are needed.

for DIR in $(cd $BASE_DIR; find . -type d -not -path "."  | sed  's#^./##')
do

  case $DIR in

    # Ignore the git directory.

    \.git) ;;
    \.git/*) ;;

    # Ignore scripts and special cases directories.

    bin) ;;
    bin/*) ;;

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

chmod go-rwx $HOME/.ssh $HOME/.local

# Copy the dotfiles.

for ITEM in $(cd $BASE_DIR; find . -type f  | sed  's#^./##')
do

  case $ITEM in

    # Ignore repo files.

    \.git/*) ;;
    \.git*) ;;

    # Ignore scripts and files that are special cases.

    bin/*) ;;
    etc/*) ;;

    # Copy everything else.

    *) cp $BASE_DIR/$ITEM "$HOME/.${ITEM}" ;;

  esac

done

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

# Check if vim-plug has changed.

VIM_PLUG_TMP=$(mktemp)
if curl -fs -o $VIM_PLUG_TMP $VIM_PLUG_URL
then
  if ! diff "${BASE_DIR}/etc/plug.vim" "${VIM_PLUG_TMP}" &>/dev/null
  then
    echo
    echo "Warning: please review upstream changes to etc/vim-plug with"
    echo "curl -o ${BASE_DIR}/etc/plug.vim $VIM_PLUG_URL"
    echo
  fi
fi

# Configure Vim using our copy of vim-plug.

mkdir -p "${HOME}/.vim/autoload"
cp -f "${BASE_DIR}/etc/plug.vim" "${HOME}/.vim/autoload/plug.vim"
vim -c :PlugInstall -c :qa! >&/dev/null

# Copy the necessary files to the Windows roaming profile if one is being used.

if [ "${SHELL_ENVIRONMENT}" = "gitbash" ]
then
  PROFILEDRIVE=`echo $USERPROFILE | cut -d'\' -f1`
  if [ "$PROFILEDRIVE" != "$HOMEDRIVE" ]
  then
    ROAMING_HOME=`cygpath $HOMEDRIVE$HOMEPATH`
    if [ -d "${ROAMING_HOME}" ]
    then

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
fi
