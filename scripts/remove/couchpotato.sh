#!/bin/bash
#Couchpotato Removal

user=$(cut -d: -f1 < /root/.master.info)
systemctl disable --now couchpotato > /dev/null 2>&1
rm /etc/systemd/system/couchpotato.service
rm -rf /home/${user}/couchpotato
rm -rf /home/${user}/.venv/couchpotato
if [ -z "$(ls -A /home/${user}/.venv)" ]; then
   rm -rf  /home/${user}/.venv
fi
rm -f /etc/nginx/apps/couchpotato.conf
systemctl reload nginx
rm /install/.couchpotato.lock
