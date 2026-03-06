# Configuration.

NAME="Hannah Morrison"
DEFAULT_EMAIL="139557138+hbmorrison@users.noreply.github.com"

# If no email address has been provided as an argument, use the defaults.

if [ -z ${1:+z} ]
then

  # Check if a gitconfig file already exists.

  if [ -r "${HOME}/.gitconfig" ]
  then

    # If so, extract the user name and email config from the existing gitconfig
    # file, replace it with the new gitconfig file, then replace the original
    # user name and email config.

    notice "extracting user section from .gitconfig"
    TEMP_USER_SECTION=`mktemp`
    awk -f "${ETC_DIR}/gitconfig.awk" "${HOME}/.gitconfig" > $TEMP_USER_SECTION \
     && pass || fail
    notice "copying .gitconfig file"
    cp -f "${ETC_DIR}/gitconfig" "${HOME}/.gitconfig" && pass || fail
    notice "replacing user section in .gitconfig"
    cat $TEMP_USER_SECTION >> "${HOME}/.gitconfig" && pass || fail
    rm -f $TEMP_USER_SECTION
  else

    # Otherwise, copy the new gitconfig file and set the default user name and
    # email.

    cp -f "${ETC_DIR}/gitconfig" "${HOME}/.gitconfig"
    notice "Setting git user.name to ${NAME}"
    git config --global user.name "${NAME}" &>/dev/null \
     && pass || fail
    notice "Setting git user.email to ${DEFAULT_EMAIL}"
    git config --global user.email "${DEFAULT_EMAIL}" &>/dev/null \
     && pass || fail
  fi
else

  # Set the user name.

  CURRENT_NAME=$(git config --global user.name)
  if [ "${NAME}" != "${CURRENT_NAME}" ]
  then
    notice "Setting git user.name to ${NAME}"
    git config --global user.name "${NAME}" &>/dev/null \
     && pass || fail
  fi

  # Set the new user email address.

  notice "Setting git user.email to ${1}"
  git config --global user.email "${1}" &>/dev/null \
   && pass || fail
fi
