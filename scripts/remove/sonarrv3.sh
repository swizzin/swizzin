#!/bin/bash
log="/root/logs/swizzin.log"

apt-get remove -yq sonarr --purge >> $log 2>&1
rm -rf /var/lib/sonarr
if [[ -f /install/.nginx.lock ]]; then 
    rm /etc/nginx/apps/sonarrv3.conf
    systemctl reload nginx >> $log 2>&1
fi

rm /install/.sonarrv3.lock