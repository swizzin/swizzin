#!/bin/bash
#
# Uninstaller for sickrage
#
user=$(cut -d: -f1 < /root/.master.info)
systemctl disable sickrage@${user}
systemctl stop sickrage@${user}
sudo rm /etc/nginx/apps/sickrage.conf > /dev/null 2>&1
sudo rm /etc/systemd/sickrage@.service > /dev/null 2>&1
sudo rm /install/.sickrage.lock
service nginx force-reload
rm -rf /home/$user/.sickrage
rm -f /install/.sickrage.lock