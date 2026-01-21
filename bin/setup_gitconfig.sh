# Configuration.

NAME="Hannah Morrison"
DEFAULT_EMAIL="139557138+hbmorrison@users.noreply.github.com"

# Set the name.

git config --global user.name "${NAME}"

# Check if an email address has been provided as an argument.

if [ ! -z ${1:+z} ]
then

  # If it has, overwrite any existing email address.

  git config --global user.email "${1}"

else

  # Otherwise, set the default email address if one has not been set already.

  CURRENT_EMAIL=$(git config --global user.email)

  if [ -z ${CURRENT_EMAIL:+z} ]
  then
    git config --global user.email "${DEFAULT_EMAIL}"
  fi

fi
