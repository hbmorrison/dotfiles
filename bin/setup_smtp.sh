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

SENDER_DOMAIN=`echo $SENDER_ADDR | cut -d@ -f2`

# Update package lists.

echo -n "Updating package lists... "

if $SUDO apt update -y &>/dev/null
then
  echo "Done"
else
  echo
  echo "Error: run $SUDO apt update -y"
  exit 1
fi


# Do not prompt for postfix configuration.

export DEBIAN_FRONTEND=noninteractive

# Install postfix and dependencies.

$SUDO apt install -y postfix libsasl2-modules

# Get the SMTP password.

while true
do
  read -s -p "${SETUP_SCRIPT} ${SUB_SCRIPT}: enter SMTP password: " SMTP_PASSWORD
  echo
  read -s -p "${SETUP_SCRIPT} ${SUB_SCRIPT}: retype SMTP password: " RETYPE
  echo
  if [ "${SMTP_PASSWORD}" != "${RETYPE}" ]
  then
    echo "${SETUP_SCRIPT} ${SUB_SCRIPT}: sorry, passwords do not match."
    continue
  fi
  if [ "${SMTP_PASSWORD}" = "" ]
  then
    echo "${SETUP_SCRIPT} ${SUB_SCRIPT}: sorry, password must not be empty."
    continue
  fi
  break
done

# Create Postfix main.cf.

cat  > /etc/postfix/main.cf <<MAIN_CF
relayhost = [${SMTP_SERVER}]:587

alias_maps = regexp:{
 {/.*/i $RCPT_ADDR}
}
alias_database = \$alias_maps

myorigin = $SENDER_DOMAIN" >> /etc/postfix/main.cf
mydestination = $SENDER_DOMAIN, \$myhostname, localhost.\$mydomain, localhost
MAIN_CF

cat $ETC_DIR/main.cf >> /etc/postfix.main.cf

# Create SASL password file and canonical sender file.

echo "${SMTP_SERVER}	${SMTP_USERNAME}:${SMTP_PASSWORD}" > /etc/postfix/sasl_passwd
echo "/.+/	${SENDER_ADDR}" > /etc/postfix/sender_canonical

# Secure the files and reload them.

chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sender_canonical
chown root:root /etc/postfix/sasl_passwd /etc/postfix/sender_canonical

postmap /etc/postfix/sasl_passwd
postmap /etc/postfix/sender_canonical

# Restart Postfix.

systemctl restart postfix.service

# Send a test message.

echo "Test message" | mail -s "Test message from ${HOSTNAME}" $RCPT_ADDR
