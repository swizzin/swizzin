#!/bin/bash
# Flood uninstaller
# Author: liara

systemctl disable flood --now -q
rm /etc/systemd/system/flood.service
npm -g remove flood

userdel -rf flood

if [ -f "/etc/nginx/apps/flood.conf" ]; then
    rm /etc/nginx/apps/flood.config
    systemctl reload nginx
fi

rm /install/.flood.lock
