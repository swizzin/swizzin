#!/usr/bin/env bash
#
systemctl -q stop "jellyfin.service"
#
apt_remove --purge jellyfin jellyfin-ffmpeg
#
[[ -d "/var/lib/jellyfin" ]] && rm -rf "/var/lib/jellyfin" || :
[[ -d "/var/log/jellyfin" ]] && rm -rf "/var/log/jellyfin" || :
[[ -d "/var/cache/jellyfin" ]] && rm -rf "/var/cache/jellyfin" || :
[[ -d "/usr/share/jellyfin/web" ]] && rm -rf "/usr/share/jellyfin/web" || :
#
# Remove the nginx conf and reload nginx.
if [[ -f "/install/.nginx.lock" ]]; then 
    rm -f "/etc/nginx/apps/jellyfin.conf"
    systemctl -q reload "nginx.service"
fi
#
[[ -d "/install/.jellyfin.lock" ]] && rm -f "/install/.jellyfin.lock" || :
#
exit
