#!/usr/bin/env bash
#
# Set the required variables
username="$(cat /root/.master.info | cut -d: -f1)"
#
# Define the removal function for jellyfin.
function remove_jellyfin() {
    systemctl stop -q "jellyfin.service"
    #
    systemctl disable -q "jellyfin.service"
    #
    rm -f "/etc/systemd/system/jellyfin.service"
    #
    kill -9 $(ps xU ${username} | grep "/opt/jellyfin/jellyfin -d /home/${username}/.config/Jellyfin$" | awk '{print $1}') >/dev/null 2>&1
    #
    rm -rf "/opt/jellyfin"
    rm -rf "/opt/ffmpeg"
    rm -rf "/home/${username}/.config/Jellyfin"
    #
    if [[ -f /install/.nginx.lock ]]; then
        rm -f "/etc/nginx/apps/jellyfin.conf"
        systemctl reload nginx
    fi
    #
    rm -f "/install/.jellyfin.lock"
}
#
# run the removal function
remove_jellyfin
