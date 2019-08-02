#!/usr/bin/env bash
#
username="$(cut -d: -f1 < /root/.master.info)"
#
function remove_filebrowser() {
    systemctl stop "filebrowser.service"
    #
    systemctl disable "filebrowser.service"
    #
    rm -f "/etc/systemd/system/filebrowser.service"
    #
    kill -9 $(ps xU ${username} | grep "/home/${username}/bin/filebrowser -d /home/${username}/.config/Filebrowser/filebrowser.db$" | awk '{print $1}') >/dev/null 2>&1
    #
    rm -f "/home/${username}/bin/filebrowser"
    rm -rf "/home/${username}/.config/Filebrowser"
    #
    if [[ -f /install/.nginx.lock ]]; then
        rm -f "/etc/nginx/apps/filebrowser.conf"
        service nginx reload
    fi
    #
    rm -f "/install/.filebrowser.lock"
}

remove_filebrowser
