#!/bin/bash

rm -rf /opt/.venv/calibre-web
rm -rf /opt/calibre-web

systemctl disable --now -q calibre-web
rm /etc/systemd/system/calibre-web.service
systemctl daemon-reload

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/calibre-web.conf
    systemctl reload nginx
fi

userdel calibreweb -f -r >> "$log" 2>&1

rm /install/.calibre-web.lock
