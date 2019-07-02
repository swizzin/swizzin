#!/bin/bash
user=$(cat /root/.master.info | cut -d: -f1)
systemctl disable --now lidarr

rm -rf /home/$user/Lidarr
rm -rf /home/$user/.config/Lidarr/
rm -rf /etc/nginx/apps/lidarr.conf
rm -rf /install/.lidarr.lock
rm -rf /etc/systemd/system/lidarr.service
systemctl reload nginx