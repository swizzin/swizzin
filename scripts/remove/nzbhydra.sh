#!/bin/bash

user=$(cut -d: -f1 < /root/.master.info)
systemctl disable --now -q nzbhydra
rm -rf /opt/nzbhydra
rm -rf /home/${user}/.config/nzbhydra
rm -rf /opt/.venv/nzbhydra
if [ -z "$(ls -A /opt/.venv)" ]; then
   rm -rf  /opt/.venv
fi

rm /etc/systemd/system/nzbhydra.service
rm -f /etc/nginx/apps/nzbhydra.conf
rm /install/.nzbhydra.lock
systemctl reload nginx
