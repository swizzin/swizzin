#!/bin/bash
# Medusa Uninstaller for Swizzin
# Author: liara
user=$(cut -d: -f1 < /root/.master.info)

systemctl disable medusa
systemctl stop medusa

sudo rm /etc/nginx/apps/medusa.conf > /dev/null 2>&1
sudo rm /etc/systemd/medusa.service > /dev/null 2>&1
systemctl reload nginx
rm -rf /home/${user}/medusa
rm -rf /home/$user/.venv/medusa
if [ -z "$(ls -A /home/$user/.venv)" ]; then
   rm -rf  /home/$user/.venv
fi

sudo rm /install/.medusa.lock


