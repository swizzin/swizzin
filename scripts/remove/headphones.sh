#!/bin/bash

user=$(cut -d: -f1 < /root/.master.info)

systemctl disable --now -q headphones

rm /etc/systemd/system/headphones.service
rm -f /etc/nginx/apps/headphones.conf
rm -rf /opt/headphones
rm -rf /opt/.venv/headphones
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi
rm /install/.headphones.lock
systemctl reload nginx
