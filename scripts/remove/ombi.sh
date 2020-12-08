#!/bin/bash
systemctl disable -q --now ombi
if [[ -f /install/.nginx.lock ]]; then
    rm -f /etc/nginx/apps/ombi.conf
    systemctl reload nginx
fi

rm /etc/apt/sources.list.d/ombi.list

apt_remove ombi

if [[ -d /opt/ombi ]]; then
    rm -rf /opt/ombi
    rm -rf /etc/ombi
fi

if [[ -d /opt/Ombi ]]; then
    rm -rf /opt/Ombi
    rm -rf /etc/Ombi
fi

rm /install/.ombi.lock
