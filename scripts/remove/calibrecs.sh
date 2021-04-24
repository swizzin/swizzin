#!/usr/bin/env bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [ -z "$CALIBRE_LIBRARY_USER" ]; then
    CALIBRE_LIBRARY_USER=$(_get_master_username)
fi

# if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
#     CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
# fi

systemctl disable --now -q calibrecs
rm /etc/systemd/system/calibrecs.service

rm -rf /home/$CALIBRE_LIBRARY_USER/.config/calibrecs

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/calibrecs.conf
    systemctl reload nginx
fi
rm /install/.calibrecs.lock
