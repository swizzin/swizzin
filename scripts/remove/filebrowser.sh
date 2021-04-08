#!/usr/bin/env bash
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#
username=$(_get_master_username)
#
function remove_filebrowser() {
    systemctl disable -q --now "filebrowser" &>> "${log}"
    #
    rm -f "/etc/systemd/system/filebrowser.service"
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
