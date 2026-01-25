# Configuration.

DOTFILES_ORIGIN_URL=$(git -C $BASE_DIR remote -v 2>/dev/null | awk '/(push)/ {print $2}')
DOTFILES_ORIGIN_DIR=$(dirname $DOTFILES_ORIGIN_URL)
DOTVIM_ORIGIN_URL="${DOTFILES_ORIGIN_DIR}/dotvim.git"
DOTVIM_BRANCH=$(git -C $BASE_DIR branch --show-current)
VIM_DIR="${HOME}/.vim"

# Check whether the vim directory already exists.

if [ -d $VIM_DIR ]
then

  # Check whether the remote URL of the vim directory is correct.

  VIM_DIR_ORIGIN_URL=$(git -C $VIM_DIR remote -v 2>/dev/null | awk '/(push)/ {print $2}')
  if [ $VIM_DIR_ORIGIN_URL = $DOTVIM_ORIGIN_URL ]
  then

    # Check that the current branch is correct.

    VIM_DIR_BRANCH=$(git -C $VIM_DIR branch --show-current 2>/dev/null)
    if [ $VIM_DIR_BRANCH != $DOTVIM_BRANCH ]
    then

      # If the branch is not correct, checkout the correct branch.

      echo -n "Updating vim directory branch to ${DOTVIM_BRANCH}... "
      if ! git -C $VIM_DIR checkout $DOTVIM_BRANCH &>/dev/null
      then
        echo "Failed"

        # If the checkout fails, checkout the main branch as a fallback.

        echo -n "Updating vim directory branch to main... "
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
  else
    echo "Error: git origin in ${VIM_DIR} does not match ${DOTVIM_ORIGIN_URL}"
    exit 1
  fi

else

  # If the vim directory does not exist, clone it.

  echo -n "Cloning the $DOTVIM_BRANCH branch of the vim directory... "
  if git clone -b $DOTVIM_BRANCH $DOTVIM_ORIGIN_URL $VIM_DIR &>/dev/null
  then
    echo "Done"
  else
    echo "Failed"

    # If the clone fails, clone from the main branch as a fallback.

    echo -n "Cloning the default branch of the vim directory... "
    if git clone $DOTVIM_ORIGIN_URL $VIM_DIR &>/dev/null
    then
      echo "Done"
    else
      echo
      echo "Error: run git clone $DOTVIM_ORIGIN_URL $VIM_DIR"
      exit 1
    fi
  fi

fi

# Pull and update the submodules.

echo -n "Pulling the latest version of the vim directory... "
if git -C $VIM_DIR pull &>/dev/null
then
  echo "Done"
else
  echo
  echo "Error: run git -C $VIM_DIR pull"
fi

echo -n "Updating submodules... "
if git -C $VIM_DIR submodule update --init --recursive &>/dev/null
then
  echo "Done"
else
  echo
  echo "Error: run git -C $VIM_DIR submodule update --init --recursive"
fi

# Copy the vimrc file.

echo -n "Updating vimrc... "
cp -f $BASE_DIR/vimrc "${HOME}/.vimrc"
echo "Done"

# Update the gitconfig file.

$BIN_DIR/setup gitconfig
