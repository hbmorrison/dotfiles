# Configuration.

DOTFILES_ORIGIN_URL=$(git -C $BASE_DIR remote -v 2>/dev/null | awk '/(push)/ {print $2}')
DOTFILES_ORIGIN_DIR=$(dirname $DOTFILES_ORIGIN_URL)
DOTVIM_ORIGIN_URL="${DOTFILES_ORIGIN_DIR}/dotvim.git"
DOTFILES_BRANCH=$(git -C $BASE_DIR branch --show-current)
VIM_DIR="${HOME}/.vim"

# Do not change the branch if the dotfiles branch is a git flow branch.

case $DOTFILES_BRANCH in
  feature-*) ;&
  bugfix-*)  ;&
  release-*) ;&
  hotfix-*)  ;&
  support-*) DOTFILES_BRANCH="main" ;;
esac

# Check whether the vim directory already exists.

if [ -d $VIM_DIR ]
then
  VIM_DIR_ORIGIN_URL=$(git -C $VIM_DIR remote -v 2>/dev/null | awk '/(push)/ {print $2}')

  # If it does, make sure that the git origin of the vim directory is correct.

  notice "checking that $VIM_DIR git origin is correct"
  [ "${VIM_DIR_ORIGIN_URL}" = $DOTVIM_ORIGIN_URL ] \
   && pass || fail "git origin in ${VIM_DIR} does not match ${DOTVIM_ORIGIN_URL}"

  # Check that the current branch is correct.

  VIM_DIR_BRANCH=$(git -C $VIM_DIR branch --show-current 2>/dev/null)
  if [ $VIM_DIR_BRANCH != $DOTFILES_BRANCH ]
  then
    notice "updating vim directory branch to ${DOTFILES_BRANCH}"
    if git -C $VIM_DIR checkout $DOTFILES_BRANCH &>/dev/null
    then
      pass
    else
      fail

      # Checkout the main branch as a fallback.

      [ $DOTFILES_BRANCH != "main" ] \
       && notice "updating vim directory branch to main" \
       && git -C $VIM_DIR checkout main \
        &>/dev/null && pass || fail "run git -C $VIM_DIR checkout main manually"
    fi
  fi
else

  # Clone the vim directory.

  notice "cloning the $DOTFILES_BRANCH branch of the vim directory"
  if git clone -b $DOTFILES_BRANCH $DOTVIM_ORIGIN_URL $VIM_DIR &>/dev/null
  then
    pass
  else
    fail

    # If the clone fails, clone from the main branch as a fallback.

    notice "Cloning the default branch of the vim directory"
    git clone $DOTVIM_ORIGIN_URL $VIM_DIR \
     &>/dev/null && pass || fail "run git clone $DOTVIM_ORIGIN_URL $VIM_DIR"
  fi
fi

# Pull and update the submodules.

notice "pulling the latest version of the vim directory"
git -C $VIM_DIR pull &>/dev/null && pass || fail "run git -C $VIM_DIR pull"

notice "updating submodules"
git -C $VIM_DIR submodule update --init --recursive &>/dev/null \
 && pass || fail "run git -C $VIM_DIR submodule update --init --recursive"

# Copy the vimrc file.

notice "updating vimrc"
cp -f $BASE_DIR/vimrc "${HOME}/.vimrc" && pass || fail
