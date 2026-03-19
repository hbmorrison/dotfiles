# Configuration.

SECURE_DIRECTORIES=".config .gnupg .ssh"

# Update dotfiles repo.

#notice "pulling latest version of dotfiles repo"
#git -C $BASE_DIR pull &>/dev/null && pass || fail

# Create any directories that are needed.

notice "creating directories"
for DIR in $(cd $BASE_DIR; find . -type d -not -path "."  | sed  's#^./##')
do
  case $DIR in

    # Ignore internal directories.

    \.git) ;;
    \.git/*) ;;
    etc) ;;
    etc/*) ;;

    # Create other directories under the home directory.

    *)
      [ -d "${HOME}/.${DIR}" ] || mkdir "${HOME}/.${DIR}" &>/dev/null \
       || fatal "could not create directory ${HOME}/.${DIR}"
      ;;
  esac
done
pass

# Make sure sensitive directories are secure.

notice "securing sensitive directories"
for DIR in $SECURE_DIRECTORIES
do
  chmod go-rwx "${HOME}/${DIR}" &>/dev/null \
   || fatal "could not secure ${HOME}/${DIR}"
done
pass

# Copy the dotfiles.

notice "copying files"
for ITEM in $(cd $BASE_DIR; find . -type f  | sed  's#^./##')
do
  case $ITEM in

    # Ignore internal files.

    setup) ;;
    \.git/*) ;;
    \.git*) ;;
    etc/*) ;;

    # Copy everything else.

    *)
      cp $BASE_DIR/$ITEM "$HOME/.${ITEM}" &>/dev/null \
       || fatal "could not copy ${HOME}/.${ITEM}"
  esac
done
pass

# Add the correct username to the qmk.ini file.

sed -i -e "/USER/s/USER/${USER}/g" "${HOME}/.config/qmk/qmk.ini" &>/dev/null

# Configure Vim and Git.

setup vim "$@"
setup git "$@"
