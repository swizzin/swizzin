#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

users=($(cut -d: -f1 < /etc/htpasswd))
for u in ${users}; do
    systemctl disable --now transmission@$u > /dev/null 2>&1
    #TODO decide if other stuff should be deleted too
    rm -f /home/${u}/.config/transmission-daemon/settings.json
done
add-apt-repository --remove ppa:transmissionbt/ppa -y >> $log 2>&1
apt_remove --purge transmission-common transmission-cli transmission-daemon
rm /etc/systemd/system/transmission@.service
rm /etc/nginx/apps/transmission.conf > /dev/null 2>&1
rm /etc/nginx/conf.d/*.transmission.conf > /dev/null 2>&1
systemctl reload nginx > /dev/null 2>&1
systemctl daemon-reload

rm /install/.transmission.lock
