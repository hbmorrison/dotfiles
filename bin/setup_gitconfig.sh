# Configuration.

NAME="Hannah Morrison"
DEFAULT_EMAIL="139557138+hbmorrison@users.noreply.github.com"

# Set the name.

CURRENT_NAME=$(git config --global user.name)
if [ "${NAME}" != "${CURRENT_NAME}" ]
then
  echo -n "Setting git user.name to ${NAME}... "
  git config --global user.name "${NAME}" &>/dev/null
  echo "Done"
fi

# Check if an email address has been provided as an argument.

if [ ! -z ${1:+z} ]
then

  # If it has, overwrite any existing email address.

  echo -n "Setting git user.email to ${1}... "
  git config --global user.email "${1}" &>/dev/null
  echo "Done"

else

  # Otherwise, set the default email address if one has not been set already.

  CURRENT_EMAIL=$(git config --global user.email 2>/dev/null)
  if [ -z ${CURRENT_EMAIL:+z} ]
  then
    echo -n "Setting git user.email to ${DEFAULT_EMAIL}... "
    git config --global user.email "${DEFAULT_EMAIL}" &>/dev/null
    echo "Done"
  fi

fi
