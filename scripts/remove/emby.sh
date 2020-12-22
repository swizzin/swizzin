#!/bin/bash
# Removal script for emby

systemctl disable --now -q emby-server
dpkg -r emby-server > /dev/null 2>&1
if [[ -f /etc/apt/sources.list.d/emby-server.list ]]; then
    rm /etc/apt/sources.list.d/emby-server.list
fi
rm -rf /etc/nginx/apps/emby.conf
rm -rf /install/.emby.lock
