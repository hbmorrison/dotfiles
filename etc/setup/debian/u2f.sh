#!/bin/bash

# Configuration.

TIMESTAMP=$(date '+%Y%M%dT%H%M')
U2F_MAPPING_FILE="/etc/u2f_mappings"
PACKAGES=( "libpam-u2f" "pamu2fcfg" )
PAM_U2F_CONFIG_FILES=( "common-u2f" "common-u2f-presenceonly" )

# Services that will need u2f enabled.

PAM_U2F_SERVICES=(
  "/etc/pam.d/chfn"
  "/etc/pam.d/chsh"
  "/etc/pam.d/cron"
  "/etc/pam.d/cups"
  "/etc/pam.d/gdm-password"
  "/etc/pam.d/login"
  "/etc/pam.d/su"
  "/etc/pam.d/sudo-i"
)

# Services that need presence-only acknowledgement enabled.

PAM_U2F_PRESENCEONLY_SERVICES=(
  "/etc/pam.d/sudo"
  "/usr/lib/pam.d/polkit-1"
)

# Make sure sudo has valid credentials before starting.

setup_needs_sudo

# Update and install pam-u2f packages.

notice "installing required packages"
$SUDO apt update -y &>/dev/null \
 && $SUDO apt install -y --no-install-recommends "${PACKAGES[@]}" &>/dev/null \
 && pass || fail

# Configure access to yubikey smartcard interface.

notice "copying common-u2f config files into pam.d"
for FILE in "${PAM_U2F_CONFIG_FILES[@]}"
do
  $SUDO cp -f "${ETC_DIR}/debian/${FILE}" "/etc/pam.d/${FILE}" \
   &>/dev/null || fatal "could not copy ${FILE}"
done
pass

# Add u2f to pam.d services.

notice "adding common-u2f to pam.d services"
for SERVICE_FILE in "${PAM_U2F_SERVICES[@]}"
do
  if [ -f "${SERVICE_FILE}" ]
  then
    if ! grep -q "^@include common-u2f" "${SERVICE_FILE}"
    then
      $SUDO sed --in-place=".pam-old" \
       '/^@include common-auth/i @include common-u2f' "${SERVICE_FILE}" \
       &>/dev/null || fatal "could not update ${SERVICE_FILE}"
    fi
  fi
done
pass

# Add presence-only u2f to pam.d services.

notice "adding common-u2f-presenceonly to pam.d services"
for SERVICE_FILE in "${PAM_U2F_PRESENCEONLY_SERVICES[@]}"
do
  if ! grep -q "^@include common-u2f" "${SERVICE_FILE}"
  then
    if [ -f "${SERVICE_FILE}" ]
    then
      $SUDO sed --in-place=".pam-old" \
       '/^@include common-auth/i @include common-u2f-presenceonly' "${SERVICE_FILE}" \
       &>/dev/null || fatal "could not update ${SERVICE_FILE}"
    fi
  fi
done
pass

# Add the u2f key to the mapping file.

notice "press your hardware key now"
U2F_ENTRY=$(/usr/bin/pamu2fcfg || fatal "could not generate u2f mapping")
pass

if [ -f $U2F_MAPPING_FILE ]
then
  notice "removing existing u2f mapping for ${U2F_ENTRY/:*}"
  $SUDO sed --in-place=".${TIMESTAMP}" "/^${U2F_ENTRY/:*}:/d" ${U2F_MAPPING_FILE} \
   &>/dev/null && pass || fatal
fi

notice "adding new u2f mapping for ${U2F_ENTRY/:*}"
echo "${U2F_ENTRY}" | $SUDO tee -a ${U2F_MAPPING_FILE} \
 &>/dev/null || fatal
$SUDO chmod go-rwx ${U2F_MAPPING_FILE} \
 &>/dev/null && pass || fatal
