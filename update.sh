#!/bin/bash

# Files that must be copied into the roaming profile directory.

ROAMING_PROFILE_FILES=".bash_profile .minttyrc"

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BASE_DIR=$(dirname $THIS_SCRIPT)

# Initialise submodules.

(cd "$BASE_DIR"; git submodule update --init --recursive)

# Work out which OS and terminal is being used.

case $(cat /proc/version 2>/dev/null) in
  MSYS*|MINGW64*)            SHELL_ENVIRONMENT="gitbash" ;;
  *Chromium\ OS*)            SHELL_ENVIRONMENT="chromeos" ;;
  *microsoft-standard-WSL2*) SHELL_ENVIRONMENT="debian" ;;
  *Ubuntu*)                  SHELL_ENVIRONMENT="debian" ;;
  *Red\ Hat*)                SHELL_ENVIRONMENT="redhat" ;;
esac

# Copy the git config file, extracting and replacing the user name and email.

if [ -r "${HOME}/.gitconfig" ]
then

  TEMP_USER_SECTION=`mktemp`
  awk -f - $HOME/.gitconfig > $TEMP_USER_SECTION <<EXTRACT_USER_SECTION
BEGIN { USER_SECTION = 0; }
/^\[/ { if ( USER_SECTION == 1 ) { USER_SECTION = 0; } }
/^\[user\]/ { USER_SECTION = 1; }
{ if ( USER_SECTION == 1 ) { print; } }
EXTRACT_USER_SECTION

  cp $BASE_DIR/gitconfig $HOME/.gitconfig
  cat $TEMP_USER_SECTION >> $HOME/.gitconfig

  rm -f $TEMP_USER_SECTION

else

  cp $BASE_DIR/gitconfig $HOME/.gitconfig

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

# Ensure directories exist and are secure.

mkdir -p $HOME/.ssh $HOME/.eyaml
chmod go-rwx $HOME/.ssh $HOME/.eyaml

# Copy the dotfiles.

for ITEM in $(cd $BASE_DIR; find . -type f  | sed  's#^./##')
do

  case $ITEM in

    # Ignore repo files.

    \.git/*) ;;
    \.git*) ;;
    gitconfig) ;;
    vim-pathogen/*) ;;
    vim/*) ;;
    update.sh) ;;

    # Copy everything else.

    *) cp $BASE_DIR/$ITEM "$HOME/.${ITEM}" ;;

  esac

done

# Copy the necessary files to the Windows roaming profile if one is being used.

if [ "${SHELL_ENVIRONMENT}" = "gitbash" ]
then

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
