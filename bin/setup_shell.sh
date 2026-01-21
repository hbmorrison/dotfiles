# Configuration.

VIM_PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/refs/heads/master/plug.vim"

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

TEMP_VIM_PLUG=$(mktemp)

if curl -fs -o $TEMP_VIM_PLUG $VIM_PLUG_URL
then
  if ! diff "${BASE_DIR}/etc/plug.vim" "${TEMP_VIM_PLUG}" &>/dev/null
  then
    echo
    echo "Warning: please review upstream changes to etc/vim-plug with"
    echo "curl -o ${BASE_DIR}/etc/plug.vim $VIM_PLUG_URL"
    echo
  fi
fi

rm -f $TEMP_VIM_PLUG

# Configure Vim using our copy of vim-plug.

mkdir -p "${HOME}/.vim/autoload"
cp -f "${BASE_DIR}/etc/plug.vim" "${HOME}/.vim/autoload/plug.vim"
vim -c :PlugInstall -c :qa! >&/dev/null
