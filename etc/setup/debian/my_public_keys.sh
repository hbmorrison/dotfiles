# Public keys to import.

MY_GPG_PUBLIC_KEYS=(
  "4775913995D1E4B179DFA97A01033E1BAB44EAB5"
)

# Import my public keys and give them ultimate trust.

notice "importing my gpg public keys"
for KEY in ${MY_GPG_PUBLIC_KEYS[@]}
do
  if [ -f "${ETC_DIR}/gpg/${KEY}.asc" ]
  then
    /usr/bin/gpg --import "${ETC_DIR}/gpg/${KEY}.asc" &>/dev/null \
     || fatal "could not import ${KEY}"
    echo "${KEY}:6:" | /usr/bin/gpg --import-ownertrust &>/dev/null \
     || fatal "could not trust ${KEY}"
  else
    fatal "Public key ${KEY} does not exist"
  fi
done
pass
