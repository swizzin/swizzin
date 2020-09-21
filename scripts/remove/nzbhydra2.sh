#!/bin/bash

rm -rf /opt/nzbhydra2

systemctl disable --now nzbhydra2 -q
rm /etc/systemd/system/nzbhydra2.service

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/nzbhydra2.conf
    systemctl reload nginx -q
fi