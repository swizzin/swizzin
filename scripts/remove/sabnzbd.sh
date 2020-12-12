#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)

systemctl disable --now -q sabnzbd
rm -rf /opt/sabnzbd
rm -rf /home/$user/.config/sabnzbd
rm -rf /opt/.venv/sabnzbd
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi
rm /etc/systemd/system/sabnzbd.service
rm -f /etc/nginx/apps/sabnzbd.conf
systemctl reload nginx
rm /install/.sabnzbd.lock
