#!/bin/bash

user=$(cut -d: -f1 < /root/.master.info)
systemctl disable --now nzbhydra
rm -rf /home/${user}/nzbhydra
rm -rf /home/${user}/.config/nzbhydra
rm -rf /home/${user}/.venv/nzbhydra
if [ -z "$(ls -A /home/$user/.venv)" ]; then
   rm -rf  /home/$user/.venv
fi

rm /etc/systemd/system/nzbhydra.service
rm -f /etc/nginx/apps/nzbhydra.conf
rm /install/.nzbhydra.lock
systemctl reload nginx
