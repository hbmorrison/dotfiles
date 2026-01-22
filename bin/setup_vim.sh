# Configuration.

DOTFILES_ORIGIN_URL=$(git -C $BASE_DIR remote -v 2>/dev/null | awk '/(push)/ {print $2}')
DOTFILES_ORIGIN_DIR=$(dirname $DOTFILES_ORIGIN_URL)
DOTVIM_ORIGIN_URL="${DOTFILES_ORIGIN_DIR}/dotvim.git"
DOTVIM_BRANCH=$(git -C $BASE_DIR branch --show-current)
VIM_DIR="${HOME}/.vim"

# Check whether the Vim config directory already exists.

if [ -d $VIM_DIR ]
then

  # Check whether the remote URL of the Vim config directory is correct.

  VIM_DIR_ORIGIN_URL=$(git -C $VIM_DIR remote -v 2>/dev/null | awk '/(push)/ {print $2}')

  if [ $VIM_DIR_ORIGIN_URL = $DOTVIM_ORIGIN_URL ]
  then

    # If the remote URL is correct, check that the branch is correct.

    VIM_DIR_BRANCH=$(git -C $VIM_DIR branch --show-current)

    if [ $VIM_DIR_BRANCH != $DOTVIM_BRANCH ]
    then

      # If the branch is not correct, checkout the correct branch and, if that
      # does not succeed, checkout the main branch instead.

      echo -n "Updating Vim config branch to ${DOTVIM_BRANCH}... "
      if ! git -C $VIM_DIR checkout $DOTVIM_BRANCH &>/dev/null
      then
        echo "Failed"
        echo -n "Updating Vim config branch to main... "
        if git -C $VIM_DIR checkout main &>/dev/null
        then
          echo "Done"
        else
          echo
          echo "Error: run git -C $VIM_DIR checkout main"
        fi
      else
        echo "Done"
      fi

    fi

    # Then pull and update the submodules.

    echo -n "Pulling the latest version of the Vim config... "

    if git -C $VIM_DIR pull &>/dev/null
    then
      echo "Done"
    else
      echo
      echo "Error: run git -C $VIM_DIR pull"
    fi

    echo -n "Updating Vim config submodules... "

    if git -C $VIM_DIR submodule update --remote --merge &>/dev/null
    then
      echo "Done"
    else
      echo
      echo "Error: run git -C $VIM_DIR submodule update --remote --merge"
    fi

  else

    echo "Error: git origin in ${VIM_DIR} does not match ${DOTVIM_ORIGIN_URL}"
    exit 1

  fi

else

  # If the Vim config directory does not exist, then clone it.

  echo -n "Cloning $DOTVIM_BRANCH of the Vim config... "
  if git clone -b $DOTVIM_BRANCH $DOTVIM_ORIGIN_URL $VIM_DIR &>/dev/null
  then
    echo "Done"
  else
    echo "Failed"
    echo -n "Cloning default branch of the Vim config... "
    if git clone $DOTVIM_ORIGIN_URL $VIM_DIR &>/dev/null
    then
      echo "Done"
    else
      echo
      echo "Error: run git clone $DOTVIM_ORIGIN_URL $VIM_DIR"
    fi
  fi

fi
exit 1

# Copy the vimrc file.

echo -n "Updating vimrc... "
cp -f $BASE_DIR/vimrc "${HOME}/.vimrc"
echo "Done"

# Update the gitconfig file.

$BIN_DIR/setup gitconfig
