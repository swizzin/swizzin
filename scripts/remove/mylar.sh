#!/bin/bash
# Mylar Uninstaller for Swizzin
# Author: Public920

if [[ -f /tmp/.install.lock ]]; then
    log="/root/logs/install.log"
else
    log="/root/logs/swizzin.log"
fi

rm -rf /opt/mylar

systemctl disable --now mylar >> $log 2>&1

rm /etc/systemd/system/mylar.service
systemctl daemon-reload >> $log 2>&1

if [[ -f /install/.nginx.lock ]]; then
    rm -f /etc/nginx/apps/mylar.conf
    systemctl reload nginx
fi

rm /install/.mylar.lock
