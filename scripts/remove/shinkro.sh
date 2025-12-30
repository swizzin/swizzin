#!/bin/bash
# shinkro remover
# 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

function _remove_shinkro() {
    readarray -t users < <(_get_user_list)
    for user in "${users[@]}"; do
        systemctl disable --now -q shinkro@"${user}"
        rm -rf /home/"${user}"/.config/shinkro
    done

    rm -f /etc/systemd/system/shinkro@.service
    rm -f /usr/bin/shinkro

    systemctl daemon-reload -q

    if [[ -f /install/.nginx.lock ]]; then
        rm -f /etc/nginx/apps/shinkro.conf
        rm -f /etc/nginx/conf.d/*.shinkro.conf

        systemctl reload nginx >> "$log" 2>&1
    fi

    rm /install/.shinkro.lock
}

_remove_shinkro
