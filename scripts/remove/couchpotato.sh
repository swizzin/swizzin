#!/bin/bash
#Couchpotato Removal

user=$(cut -d: -f1 < /root/.master.info)
systemctl disable --now couchpotato > /dev/null 2>&1
rm /etc/systemd/system/couchpotato.service
rm -rf /opt/couchpotato
rm -rf /home/${user}/.config/couchpotato
rm -rf /opt/.venv/couchpotato
if [ -z "$(ls -A /opt/.venv)" ]; then
   rm -rf  /opt/.venv
fi
rm -f /etc/nginx/apps/couchpotato.conf
systemctl reload nginx
rm /install/.couchpotato.lock
