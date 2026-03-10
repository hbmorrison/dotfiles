# Configuration.

SECURE_DIRECTORIES=".config .gnupg .ssh"

# Update dotfiles repo.

notice "pulling latest version of dotfiles repo"
git -C $BASE_DIR pull &>/dev/null && pass || fail

# Create any directories that are needed.

notice "creating directories"
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
      [ -d "${HOME}/.${DIR}" ] || mkdir "${HOME}/.${DIR}" &>/dev/null \
       || fail "could not create ${HOME}/.${DIR}"
      ;;
  esac
done
pass

# Make sure sensitive directories are secure.

notice "securing sensitive directories"
for DIR in $SECURE_DIRECTORIES
do
  chmod go-rwx "${HOME}/${DIR}" &>/dev/null \
   || fail "could not secure ${HOME}/${DIR}"
done
pass

# Copy the dotfiles.

notice "copying files"
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
      cp $BASE_DIR/$ITEM "$HOME/.${ITEM}" &>/dev/null \
       || fail "could not copy ${HOME}/.${ITEM}"
  esac
done
pass

# Add the correct username to the qmk.ini file.

sed -i -e "/USER/s/USER/${USER}/g" "${HOME}/.config/qmk/qmk.ini" &>/dev/null

# Configure Vim and Git.

source $BIN_DIR/setup_vim.sh
source $BIN_DIR/setup_gitconfig.sh
