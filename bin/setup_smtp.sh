# Configuration.

PACKAGES="libsasl2-modules postfix"

# Confirm that all required variables are set.

[ -z ${SMTP_USERNAME:+z} ] && fail "SMTP_USERNAME not set"
[ -z ${SMTP_SERVER:+z} ]   && fail "SMTP_SERVER not set"
[ -z ${SENDER_ADDR:+z} ]   && fail "SENDER_ADDR not set"
[ -z ${RCPT_ADDR:+z} ]     && fail "RCPT_ADDR not set"

SENDER_DOMAIN=$(echo $SENDER_ADDR | cut -d@ -f2)

# Make sure sudo has valid credentials before starting.

if [ ! -z ${SUDO} ]
then
  if ! sudo -n /bin/true 2>/dev/null
  then
    sudo -v || fail "could not authenticate with sudo"
  fi
fi

# Update package lists.

notice "updating package lists"
$SUDO apt update -y &>/dev/null && pass || fail "unable to update package lists"

# Do not prompt for postfix configuration.

export DEBIAN_FRONTEND=noninteractive

# Install postfix and dependencies.

notice "installing required packages"
$SUDO apt install -y $PACKAGES && pass || fail "unable to install packages"

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

notice "creating postfix configuration"
cat  >/etc/postfix/main.cf <<MAIN_CF
relayhost = [${SMTP_SERVER}]:587

alias_maps = regexp:{
 {/.*/i $RCPT_ADDR}
}
alias_database = \$alias_maps

myorigin = $SENDER_DOMAIN" >> /etc/postfix/main.cf
mydestination = $SENDER_DOMAIN, \$myhostname, localhost.\$mydomain, localhost
MAIN_CF
cat $ETC_DIR/main.cf >> /etc/postfix.main.cf
pass

# Create SASL password file and canonical sender file.

notice "adding SASL password"
echo "${SMTP_SERVER}	${SMTP_USERNAME}:${SMTP_PASSWORD}" > /etc/postfix/sasl_passwd
pass
notice "setting email sender address"
echo "/.+/	${SENDER_ADDR}" > /etc/postfix/sender_canonical
pass

# Secure the files and reload them.

notice "securing postfix files"
chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sender_canonical \
 && chown root:root /etc/postfix/sasl_passwd /etc/postfix/sender_canonical \
 && pass || fail

notice "incorporating postfix files"
postmap /etc/postfix/sasl_passwd \
 && postmap /etc/postfix/sender_canonical \
 && pass || fail

# Restart Postfix.

notice "restarting postfix"
systemctl restart postfix.service && pass || fail

# Send a test message.

notice "sending test email to $RCPT_ADDR"
echo "Test message" | mail -s "Test message from ${HOSTNAME}" $RCPT_ADDR \
 && pass || fail
