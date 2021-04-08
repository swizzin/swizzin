#!/usr/bin/env bash
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#
username=$(_get_master_username)
#
function remove_filebrowser() {
    systemctl disable -q --now "filebrowser.service" &>> "${log}"
    #
    rm -f "/etc/systemd/system/filebrowser.service"
    #
    kill -9 $(ps xU ${username} | grep "/opt/filebrowser/filebrowser -d /home/${username}/.config/Filebrowser/filebrowser.db$" | awk '{print $1}') &>> "${log}"
    #
    rm -rf "/opt/filebrowser"
    rm -rf "/home/${username}/.config/Filebrowser"
    #
    if [[ -f /install/.nginx.lock ]]; then
        rm -f "/etc/nginx/apps/filebrowser.conf"
        systemctl reload nginx &>> "${log}"
    fi
    #
    rm -f "/install/.filebrowser.lock"
}

remove_filebrowser
