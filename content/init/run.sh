#!/bin/bash
# Enable Icinga2 Features
set -e

if [ "$TIMEZONE" != "" ]; then
  echo Set TIMEZONE to $TIMEZONE
  if [ ! -e /usr/share/zoneinfo/$TIMEZONE ]; then
    >&2 echo ERROR: Could not set timezone. File /usr/share/zoneinfo/$TIMEZONE does not exist.
    exit 1
  fi
  rm /etc/localtime
  ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime
else
  echo Hint: Set your timezone using TIMEZONE env var.
fi
# Icinga2 features
ENABLED_FEATURES=$(icinga2 feature list | grep "Enabled features" | cut -d: -f 2)

for f in ${ICINGA_FEATURES} ; do
  echo ${ENABLED_FEATURES} | grep api -q && continue; # feature already enabled

 # Icinga2 api setup
  if [ "${f}" == "api" ] && [ ! -e /etc/icinga2/features-enabled/api.conf ] ; then
    icinga2 api setup
    if [ ! -e /etc/icinga2/conf.d/api-users.conf ] ; then
      # Create api user for Icingaweb2
      cp /tmp/api-users.conf /etc/icinga2/conf.d/api-users.conf
      sed -r -i \
        "s/^[ \t\/]*password = .*/  password = \"${ICINGA_API_PASS}\",/g" \
        /etc/icinga2/conf.d/api-users.conf
    fi
  # Other features
  else
    icinga2 feature enable ${f}
  fi
done
#sudo mkdir -p /run/icinga2
#sudo chown icinga /run/icinga2 -R
sed -r -i \
        "s/^[ \t\/]*password = .*/  password = \"${ICINGA_API_PASS}\",/g" \
        /etc/icinga2/conf.d/api-users.conf

# Run Icinga2 daemon

echo 'Start Icinga2 Daemon'
exec dumb-init -- \
  "icinga2 daemon --log-level ${ICINGA_LOGLEVEL:-warning} --include /etc/icinga2"

#exec dumb-init -- su icinga -c \
#  "icinga2 daemon --log-level ${ICINGA_LOGLEVEL:-warning} --include /etc/icinga2"
