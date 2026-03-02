# Configuration.

SECURE_DIRECTORIES=".config .gnupg .ssh"

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

# Make sure sensitive directories are secure.

for DIR in $SECURE_DIRECTORIES
do
  notice "securing ~/${DIR} directory"
  chmod go-rwx "${HOME}/${DIR}" && pass || fail
done

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

# Add the correct username to the qmk.ini file.

sed -i -e "/USER/s/USER/${USER}/g" "${HOME}/.config/qmk/qmk.ini"

# Configure Vim and Git.

source $BIN_DIR/setup_vim.sh
source $BIN_DIR/setup_gitconfig.sh
