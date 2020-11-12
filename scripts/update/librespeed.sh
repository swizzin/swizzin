#!/bin/bash

if [[ -f /install/.librespeed.lock ]]; then
    if ! grep -q 'php\$' /etc/nginx/apps/librespeed.conf; then
        rm /etc/nginx/apps/librespeed.conf
        bash /etc/swizzin/scripts/nginx/librespeed.conf
        systemctl reload nginx
    fi
fi