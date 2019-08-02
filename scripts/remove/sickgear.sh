#!/bin/bash
#
# Uninstaller for SickGear
#
user=$(cut -d: -f1 < /root/.master.info)
systemctl disable sickgear@${user}
systemctl stop sickgear@${user}
sudo rm /etc/nginx/apps/sickgear.conf > /dev/null 2>&1
sudo rm /etc/systemd/sickgear@.service > /dev/null 2>&1
sudo rm /install/.sickgear.lock
service nginx force-reload
rm -rf /home/$user/.sickgear
rm -f /install/.sickgear.lock
