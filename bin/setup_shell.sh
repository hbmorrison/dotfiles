# Create any directories that are needed.

echo -n "Creating directories... "
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
        mkdir "${HOME}/.${DIR}"
      fi
      ;;

  esac

done
echo "Done"

# Make sure the SSH directory is secure.

echo -n "Securing SSH directory... "
chmod go-rwx $HOME/.ssh
echo "Done"


# Copy the dotfiles.

echo -n "Copying dotfiles... "
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

    *) cp $BASE_DIR/$ITEM "$HOME/.${ITEM}" ;;

  esac

done
echo "Done"

# Configure Vim.

$BIN_DIR/setup vim
