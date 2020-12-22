#!/bin/bash

apt_remove --purge sonarr

rm -rf /var/lib/sonarr
rm -rf /usr/lib/sonarr

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/sonarrv3.conf
    systemctl reload nginx >> $log 2>&1
fi

rm /install/.sonarrv3.lock
