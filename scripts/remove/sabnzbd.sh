#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)

systemctl disable --now sabnzbd
rm -rf /home/$user/sabnzbd
rm -rf /home/$user/.config/sabnzbd
rm -rf /home/$user/.venv/sabnzbd
if [ -z "$(ls -A /home/$user/.venv)" ]; then
   rm -rf  /home/$user/.venv
fi
rm /etc/systemd/system/sabnzbd.service
rm -f /etc/nginx/apps/sabnzbd.conf
systemctl reload nginx
rm /install/.sabnzbd.lock
