#!/usr/bin/env bash
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#
systemctl -q stop jellyfin.service
#
apt_remove --purge jellyfin jellyfin-ffmpeg
#
rm_if_exists /var/lib/jellyfin
rm_if_exists /var/log/jellyfin
rm_if_exists /var/cache/jellyfin
rm_if_exists /usr/share/jellyfin/web
#
# Remove the nginx conf and reload nginx.
if [[ -f /install/.nginx.lock ]]; then
    rm_if_exists /etc/nginx/apps/jellyfin.conf
    systemctl -q reload nginx.service
fi
#
rm_if_exists /install/.jellyfin.lock
#
exit
