#!/bin/bash
systemctl disable --now -q radarr
rm /etc/systemd/system/radarr.service
systemctl daemon-reload -q
rm -rf /opt/Radarr

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/radarr.conf
    systemctl reload nginx
fi

rm /install/.radarr.lock
