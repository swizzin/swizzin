#!/bin/bash
apt-get remove -yq sonarr --purge
rm -rf /var/lib/sonarr
if [[ -f /install/.nginx.lock ]]; then 
    rm /etc/nginx/apps/sonarr.conf
    systemctl reload nginx
fi