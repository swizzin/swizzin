#!/bin/bash
# Mylar Uninstaller for Swizzin
# Author: Public920

if [[ -f /tmp/.install.lock ]]; then
    log="/root/logs/install.log"
else
    log="/root/logs/swizzin.log"
fi

user=$(cut -d: -f1 < /root/.master.info)

systemctl disable --now mylar

rm /etc/systemd/system/mylar.service
rm -f /etc/nginx/apps/mylar.conf
rm -rf /opt/mylar
rm -rf /opt/.venv/mylar
if [ -z "$(ls -A /opt/.venv)" ]; then
   rm -rf  /opt/.venv
fi
rm /install/.mylar.lock
systemctl reload nginx
