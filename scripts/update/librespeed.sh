#!/bin/bash

if [[ -f /install/.librespeed.lock ]]; then
    if ! grep -q 'php\$' /etc/nginx/apps/librespeed.conf; then
        echo_progress_start "Updating Librespeed nginx config"
        rm /etc/nginx/apps/librespeed.conf
        bash /etc/swizzin/scripts/nginx/librespeed.conf
        systemctl reload nginx
        echo_progress_done
    fi
fi
