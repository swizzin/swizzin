#!/bin/sh
systemctl stop lidarr
systemctl disable lidarr
rm -rf /etc/systemd/system/lidarr.service
rm -rf /opt/Lidarr
rm -rf /etc/nginx/apps/lidarr.conf
rm -rf /install/.lidarr.lock
echo "Lidarr uninstalled!"
