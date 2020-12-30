#!/bin/bash

apt_remove --purge sonarr

rm -rf /var/lib/sonarr
rm -rf /usr/lib/sonarr

if islocked "nginx"; then
    rm /etc/nginx/apps/sonarrv3.conf
    systemctl reload nginx >> $log 2>&1
fi

unlock "sonarrv3"
