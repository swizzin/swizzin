#!/bin/bash

rm -rf /opt/.venv/calibreweb
rm -rf /opt/calibreweb

systemctl disable --now -q calibreweb
rm /etc/systemd/system/calibreweb.service
systemctl daemon-reload

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/calibreweb.conf
    systemctl reload nginx
fi

userdel calibreweb -f -r >> "$log" 2>&1

rm /install/.calibreweb.lock
