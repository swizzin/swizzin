#!/bin/bash
#
# Uninstaller for sickchill
#
user=$(cut -d: -f1 < /root/.master.info)
systemctl disable sickchill@${user}
systemctl stop sickchill@${user}
sudo rm /etc/nginx/apps/sickchill.conf > /dev/null 2>&1
sudo rm /etc/systemd/sickchill@.service > /dev/null 2>&1
sudo rm /install/.sickchill.lock
service nginx force-reload
rm -rf /home/$user/.sickchill
rm -f /install/.sickchill.lock