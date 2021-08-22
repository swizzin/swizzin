#!/bin/bash
# LazyLibrarian remove script for swizzin
# Author: Aethaeran 2021
# GPLv3

app_name="lazylibrarian"
user="$(swizdb get $app_name/owner)"

rm -rf "/opt/.venv/$app_name"
rm -rf "/opt/$app_name"
rm -rf "/home/$user/.config/$app_name"

systemctl disable --now "$app_name" --quiet
rm -rf "/etc/systemd/system/$app_name.service"

if [[ -f /install/.nginx.lock ]]; then
    rm -rf "/etc/nginx/apps/$app_name.conf"
    systemctl reload nginx
fi

rm "/install/.$app_name.lock"
