#!/bin/bash
. /etc/swizzin/sources/functions/utils
#
username="$(_get_master_username)"
#
systemctl -q stop "jellyfin.service"
#
if [[ -f /etc/systemd/system/jellyfin.service ]]; then
    #
    ## legacy start
    systemctl -q disable --now "jellyfin.service"
    rm -f "/etc/systemd/system/jellyfin.service"
    kill -9 $(ps xU ${username} | grep "/opt/jellyfin/jellyfin -d /home/${username}/.config/Jellyfin$" | awk '{print $1}') >/dev/null 2>&1
    [[ -d "/opt/jellyfin" ]] && rm -rf "/opt/jellyfin" | :
    [[ -d "/opt/ffmpeg" ]] && rm -rf "/opt/ffmpeg" | :
    [[ -d "/home/${username}/.config/Jellyfin" ]] && rm -rf "/home/${username}/.config/Jellyfin" | :
    [[ -d "/home/${username}/.cache/jellyfin" ]] && rm -rf "/home/${username}/.cache/jellyfin" | :
    [[ -d "/home/${username}/.aspnet" ]] && rm -rf "/home/${username}/.aspnet" | :
    ## legacy end
    #
else
    apt_remove --purge jellyfin jellyfin-ffmpeg
    #
    [[ -d "/var/lib/jellyfin" ]] && rm -rf /var/lib/jellyfin | :
    [[ -d "/var/log/jellyfin" ]] && rm -rf /var/log/jellyfin | :
    [[ -d "/var/cache/jellyfin" ]] && rm -rf /var/cache/jellyfin | :
    [[ -d "/usr/share/jellyfin/web" ]] && rm -rf /usr/share/jellyfin/web | :
fi
#
# Remove the nginx conf and reload nginx.
if [[ -f /install/.nginx.lock ]]; then 
    rm -f /etc/nginx/apps/jellyfin.conf
    systemctl -q reload nginx
fi
#
rm -f /install/.jellyfin.lock
#
exit
