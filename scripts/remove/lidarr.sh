#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)
systemctl disable --now lidarr

rm -rf /home/opt/lidarr
rm -rf /home/$user/.config/Lidarr/
rm -rf /install/.lidarr.lock
rm -rf /etc/systemd/system/lidarr.service
systemctl daemon-reload

if [[ -f /install/.nginx.lock ]]; then
    rm -rf /etc/nginx/apps/lidarr.conf
    systemctl reload nginx
fi