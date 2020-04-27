#!/bin/bash
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi
user=$(cut -d: -f1 < /root/.master.info)

systemctl disable --now headphones

rm /etc/systemd/system/headphones.service
rm -f /etc/nginx/apps/headphones.conf
rm -rf /home/${user}/headphones
rm -rf /home/${user}/.venv/headphones
if [ -z "$(ls -A /home/$user/.venv)" ]; then
   rm -rf  /home/$user/.venv
fi
systemctl reload nginx

