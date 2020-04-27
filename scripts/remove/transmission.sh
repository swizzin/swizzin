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
apt-get purge -y transmission-common transmission-cli transmission-daemon >> $log 2>&1
rm /etc/systemd/system/transmission@.service
systemctl daemon-reload

rm /install/.transmission.lock
