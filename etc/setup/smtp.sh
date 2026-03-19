#!/bin/bash

# Configuration.

PACKAGES="libsasl2-modules postfix"

# Confirm that all required variables are set.

[ -z ${SMTP_USERNAME:+z} ] && fail "SMTP_USERNAME not set"
[ -z ${SMTP_SERVER:+z} ]   && fail "SMTP_SERVER not set"
[ -z ${SENDER_ADDR:+z} ]   && fail "SENDER_ADDR not set"
[ -z ${RCPT_ADDR:+z} ]     && fail "RCPT_ADDR not set"

SENDER_DOMAIN=$(echo $SENDER_ADDR | cut -d@ -f2)

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Update package lists.

updating "package lists"
$SUDO apt update -y &>/dev/null && pass || fatal

# Do not prompt for postfix configuration.

export DEBIAN_FRONTEND=noninteractive

# Install postfix and dependencies.

installing "required packages"
$SUDO apt install -y $PACKAGES && pass || fatal

# Get the SMTP password.

while true
do
  read -s -p "setup ${SCRIPT}: enter SMTP password: " SMTP_PASSWORD
  echo
  read -s -p "setup ${SCRIPT}: retype SMTP password: " RETYPE
  echo
  if [ "${SMTP_PASSWORD}" != "${RETYPE}" ]
  then
    echo "setup ${SCRIPT}: sorry, passwords do not match."
    continue
  fi
  if [ "${SMTP_PASSWORD}" = "" ]
  then
    echo "setup ${SCRIPT}: sorry, password must not be empty."
    continue
  fi
  break
done

# Create Postfix main.cf.

creating "postfix main.cf"
$SUDO cat <<MAIN_CF | tee /etc/postfix/main.cf &>/dev/null && pass || fatal
relayhost = [${SMTP_SERVER}]:587

alias_maps = regexp:{
 {/.*/i $RCPT_ADDR}
}
alias_database = \$alias_maps

myorigin = $SENDER_DOMAIN" >> /etc/postfix/main.cf
mydestination = $SENDER_DOMAIN, \$myhostname, localhost.\$mydomain, localhost
MAIN_CF
cat $ETC_DIR/smtp/main.cf >> /etc/postfix.main.cf

# Create SASL password file and canonical sender file.

adding "SASL password"
echo "${SMTP_SERVER}	${SMTP_USERNAME}:${SMTP_PASSWORD}" > /etc/postfix/sasl_passwd
pass
setting "email sender address"
echo "/.+/	${SENDER_ADDR}" > /etc/postfix/sender_canonical
pass

# Secure the files and reload them.

securing "postfix files"
chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sender_canonical \
 && chown root:root /etc/postfix/sasl_passwd /etc/postfix/sender_canonical \
 && pass || fatal

installing "postfix files"
postmap /etc/postfix/sasl_passwd \
 && postmap /etc/postfix/sender_canonical \
 && pass || fatal

# Restart Postfix.

restarting "postfix"
systemctl restart postfix.service && pass || fatal

# Send a test message.

sending "test email to $RCPT_ADDR"
echo "Test message" | mail -s "Test message from ${HOSTNAME}" $RCPT_ADDR \
 && pass || fatal
