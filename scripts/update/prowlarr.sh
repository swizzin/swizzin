#!/bin/bash

if [[ -f /install/.prowlarr.lock ]]; then

    if [ -f /install/.nginx.lock ] && grep -q 'http://127.0.0.1:9696/prowlarr/$1/api' /etc/nginx/apps/prowlarr.conf; then
        echo_log_only "Fixing prowlarr nginx config"
        bash /etc/swizzin/scripts/nginx/prowlarr.sh
        systemctl reload nginx
    fi
fi
