#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

users=($(cut -d: -f1 < /etc/htpasswd))
for u in ${users[@]}; do
    echo "Shutting down transmission@$u"
    systemctl stop transmission@"$u" > $log 2>&1
    systemctl disable transmission@"$u" > $log 2>&1
    rm -f /home/${u}/.config/transmission-daemon/settings.json
done

add-apt-repository --remove ppa:transmissionbt/ppa -y >> $log 2>&1
apt-get purge -y transmission-common transmission-cli transmission-daemon >> $log 2>&1
rm /etc/systemd/system/transmission@.service
rm /etc/nginx/apps/transmission.conf > $log 2>&1
rm /etc/nginx/conf.d/*.transmission.conf > $log 2>&1
systemctl reload nginx > $log 2>&1
systemctl daemon-reload

rm /install/.transmission.lock
