#!/bin/bash

if [[ -f /install/.readarr.lock ]]; then
    if [[ -f /install/.nginx.lock ]]; then
        # check for /feed/calendar auth bypass
        if grep -q "8787/readarr" "/etc/nginx/apps/readarr.conf" || ! grep -q "calendar" /etc/nginx/apps/readarr.conf; then
            echo_progress_start "Upgrading nginx config for Readarr"
            bash /etc/swizzin/scripts/nginx/readarr.sh
            systemctl reload nginx -q
            echo_progress_done "nginx conf for Readarr upgraded"
        fi
    fi
fi
