#!/bin/bash
systemctl disable --now -q radarr
rm /etc/systemd/system/radarr.service
systemctl daemon-reload -q
rm -rf /opt/Radarr

if islocked "nginx"; then
    rm /etc/nginx/apps/radarr.conf
    systemctl reload nginx
fi

unlock "radarr"
