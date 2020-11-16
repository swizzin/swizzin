#!/bin/bash
user=$(_get_master_username)
systemctl disable --now -q lidarr

rm -rf /home/$user/Lidarr
rm -rf /home/$user/.config/Lidarr/
rm -rf /etc/nginx/apps/lidarr.conf
rm -rf /install/.lidarr.lock
rm -rf /etc/systemd/system/lidarr.service
systemctl reload nginx
