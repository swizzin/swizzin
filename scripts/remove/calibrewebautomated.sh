#!/bin/bash

rm -rf /opt/.venv/calibrewebautomated
rm -rf /opt/calibrewebautomated

systemctl disable --now -q calibrewebautomated
rm /etc/systemd/system/calibrewebautomated.service
systemctl daemon-reload

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/calibrewebautomated.conf
    systemctl reload nginx
fi

userdel calibrewebautomated -f -r >> "$log" 2>&1

# Only clear swizdb keys if none of the calibre variants are present
if [ ! -f /install/.calibrecs.lock ] && [ ! -f /install/.calibre.lock ] && [ ! -f /install/.calibreweb.lock ]; then
    echo_log_only "Clearing calibre swizdb"
    swizdb clear calibre/library_path
    swizdb clear calibre/library_user
fi

rm /install/.calibrewebautomated.lock
