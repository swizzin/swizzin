#!/bin/bash
# Librespeed uninstaller for swizzin
# Author: hwcltjn

function _removeLibreSpeed() {
    sudo rm -r /srv/librespeed
    sudo rm /etc/nginx/apps/librespeed.conf
    sudo unlock "librespeed"
    systemctl reload nginx
}

_removeLibreSpeed
