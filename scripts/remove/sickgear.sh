#!/bin/bash
#
# Uninstaller for SickGear
#
user=$(cut -d: -f1 < /root/.master.info)
systemctl disable --now sickgear
sudo rm /etc/nginx/apps/sickgear.conf > /dev/null 2>&1
sudo rm /etc/systemd/sickgear.service > /dev/null 2>&1
sudo rm /install/.sickgear.lock
systemctl reload nginx
rm -rf /home/$user/sickgear
rm -rf /home/$user/.venv/sickgear
if [ -z "$(ls -A /home/$user/.venv)" ]; then
   rm -rf  /home/$user/.venv
fi
rm -f /install/.sickgear.lock
