#!/bin/bash

users=($(cut -d: -f1 < /etc/htpasswd))
for u in ${users}; do
  systemctl disable --now transmission@$u > /dev/null 2>&1
  rm -rf /home/${u}/.config/transmission-daemon
done

apt-get purge -y transmission-common transmission-cli transmission-daemon
rm /etc/systemd/system/transmission@.service
systemctl daemon-reload

rm /install/.transmission.lock
