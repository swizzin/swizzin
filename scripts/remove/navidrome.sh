#!/bin/bash
# navidrome remover
# byte 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

user="$(_get_master_username)"

function _remove_navidrome() {
    systemctl disable --now -q navidrome.service

    rm_if_exists /etc/systemd/system/navidrome.service
    rm_if_exists /opt/navidrome
    rm_if_exists "/home/${user}/.config/navidrome"

    systemctl daemon-reload -q

    if [[ -f /install/.nginx.lock ]]; then
        rm_if_exists /etc/nginx/apps/navidrome.conf
        systemctl reload -q nginx &>> "${log}"
    fi

    rm_if_exists /install/.navidrome.lock
}

_remove_navidrome
