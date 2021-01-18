#!/usr/bin/env bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [ -z "$CALIBRE_LIBRARY_USER" ]; then
    CALIBRE_LIBRARY_USER=$(_get_master_username)
fi

# if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
#     CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
# fi

systemctl disable --now -q calibre-cs
rm /etc/systemd/system/calibre-cs.service

rm -rf /home/$CALIBRE_LIBRARY_USER/.config/calibre-cs

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/calibre-cs.service
    systemctl reload nginx
fi
rm /install/.calibre-cs.lock
