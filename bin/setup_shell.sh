# Update dotfiles repo.

notice "pulling latest version of dotfiles repo"
git -C $BASE_DIR pull &>/dev/null && pass || fail

# Create any directories that are needed.

for DIR in $(cd $BASE_DIR; find . -type d -not -path "."  | sed  's#^./##')
do

  case $DIR in

    # Ignore the git and vim directories.

    \.git) ;;
    \.git/*) ;;
    \.vim) ;;
    \.vim/*) ;;

    # Ignore scripts and special cases directories.

    bin) ;;
    bin/*) ;;

    etc) ;;
    etc/*) ;;

    # Create other directories under the home directory.

    *)
      if [ ! -d "${HOME}/.${DIR}" ]
      then
        notice "creating ${HOME}/.${DIR}"
        mkdir "${HOME}/.${DIR}" && pass || fail
      fi
      ;;

  esac

done

# Make sure the SSH directory is secure.

notice "securing SSH directory"
chmod go-rwx $HOME/.ssh && pass || fail

# Copy the dotfiles.

for ITEM in $(cd $BASE_DIR; find . -type f  | sed  's#^./##')
do

  case $ITEM in

    # Ignore repo files.

    \.git/*) ;;
    \.git*) ;;

    # Ignore the vimrc file.

    vimrc) ;;

    # Ignore scripts and files that are special cases.

    bin/*) ;;
    etc/*) ;;

    # Copy everything else.

    *)
      notice "updating ~/.${ITEM}"
      cp $BASE_DIR/$ITEM "$HOME/.${ITEM}" && pass || fail

  esac

done

# Configure Vim and Git.

source $BIN_DIR/setup_vim.sh
source $BIN_DIR/setup_gitconfig.sh
