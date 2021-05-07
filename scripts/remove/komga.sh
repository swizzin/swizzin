#!/bin/bash

# Log to Swizzin.log
export log=/root/logs/swizzin.log
touch $log

systemctl disable --now -q komga
rm /etc/systemd/system/komga.service
systemctl daemon-reload -q

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/komga.conf
    systemctl reload nginx
fi

rm /install/.komga.lock
rm -rf "/opt/komga/"
