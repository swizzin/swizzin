#!/bin/bash

if [[ -f /install/.prowlarr.lock ]]; then
    if [[ -f /install/.nginx.lock ]]; then
        if grep -q "9696/prowlarr" /etc/nginx/apps/prowlarr.conf; then
            echo_progress_start "Upgrading nginx config for Prowlarr"
            bash /etc/swizzin/scripts/nginx/prowlarr.sh
            systemctl reload nginx -q
            echo_progress_done "Nginx conf for Prowlarr upgraded"
        fi
    fi
fi
