#!/bin/bash

# Locate the base directory of the repository.

THIS_SCRIPT=$(readlink -f $0)
BIN_DIR=$(dirname $THIS_SCRIPT)
BASE_DIR=$(dirname $BIN_DIR)
SCRIPT_NAME=$(basename $THIS_SCRIPT)

# Check that this script is being run by root.

if [ `id -u` -ne 0 ]
then
  echo "Error: run as root"
  exit 1
fi

# Configuration.

if [ "x${SMTP_USERNAME}" = "x" ]
then
  echo "Error: SMTP_USERNAME not set"
  exit 1
fi

if [ "x${SMTP_SERVER}" = "x" ]
then
  echo "Error: SMTP_SERVER not set"
  exit 1
fi

if [ "x${SENDER_ADDR}" = "x" ]
then
  echo "Error: SENDER_ADDR not set"
  exit 1
fi

if [ "x${RCPT_ADDR}" = "x" ]
then
  echo "Error: RCPT_ADDR not set"
  exit 1
fi

# Work out which OS and terminal is being used.

if [ -f /etc/os-release ]
then
  . /etc/os-release
else
  echo "Error: /etc/os-release not found"
  exit 1
fi

case $ID in
  debian)
      apt update
      ;;
  *)
    echo "Error: operating system not supported"
    exit 1
esac

# Do not prompt for postfix configuration.

export DEBIAN_FRONTEND=noninteractive

# Install postfix and dependencies.

apt install -y postfix libsasl2-modules

# Get the SMTP password.

while true
do
  read -s -p "${SCRIPT_NAME} enter SMTP password: " SMTP_PASSWORD
  echo
  read -s -p "${SCRIPT_NAME} retype SMTP password: " RETYPE
  echo
  if [ "${SMTP_PASSWORD}" != "${RETYPE}" ]
  then
    echo "${SCRIPT_NAME} sorry, passwords do not match."
    continue
  fi
  if [ "${SMTP_PASSWORD}" = "" ]
  then
    echo "${SCRIPT_NAME} sorry, password must not be empty."
    continue
  fi
  break
done

# Create Postfix main.cf.

echo "relayhost = [${SMTP_SERVER}]:587" > /etc/postfix/main.cf
cat $BASE_DIR/etc/main.cf >> /etc/postfix.main.cf

sed -i -e 's/^root:/#root:/' /etc/aliases
sed -i -e "\$a root: ${RCPT_ADDR}" /etc/aliases

# Create SASL password file and canonical sender file.

echo "${SMTP_SERVER}  ${SMTP_USERNAME}:${SMTP_PASSWORD}" > /etc/postfix/sasl_passwd
echo "/.+/  ${SENDER_ADDR}" > /etc/postfix/sender_canonical

# Secure the files and reload them.

chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sender_canonical
chown root:root /etc/postfix/sasl_passwd /etc/postfix/sender_canonical

postmap /etc/postfix/sasl_passwd
postmap /etc/postfix/sender_canonical

# Restart Postfix.

systemctl restart postfix.service

# Send a test message.

echo "Test message" | mail -s "Test message from ${HOSTNAME}" $RCPT_ADDR
