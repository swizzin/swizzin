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
#   rm -rf /home/${u}/.config/transmission-daemon
    mv /home/${u}/.config/transmission-daemon/settings.json /home/${u}/.config/transmission-daemon/settings.json.bak
done

apt-get purge -y transmission-common transmission-cli transmission-daemon >> $log 2>&1
rm /etc/systemd/system/transmission@.service
systemctl daemon-reload

rm /install/.transmission.lock
