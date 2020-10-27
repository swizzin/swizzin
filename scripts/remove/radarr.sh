#!/bin/sh
systemctl stop -q radarr
systemctl disable -q radarr
rm -rf /etc/systemd/system/radarr.service
systemctl daemon-reload -q
rm -rf /opt/Radarr

if [[ -f /install/.nginx.lock ]]; then
    rm -rf /etc/nginx/apps/radarr.conf
    systemctl reload nginx
fi

rm -rf /install/.radarr.lock
