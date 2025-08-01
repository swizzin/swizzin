#!/bin/bash
# netronome remover
# soup 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

function _remove_netronome() {
    users=($(_get_user_list))
    for user in ${users[@]}; do
        systemctl disable --now -q netronome@${user}
        rm -rf /home/${user}/.config/netronome
    done

    rm -f /etc/systemd/system/netronome@.service
    rm -f /usr/bin/netronome

    systemctl daemon-reload -q

    if [[ -f /install/.nginx.lock ]]; then
        rm -f /etc/nginx/apps/netronome.conf
        rm -f /etc/nginx/conf.d/*.netronome.conf

        systemctl reload nginx >> "$log" 2>&1
    fi

    rm /install/.netronome.lock
}

_remove_netronome
