#!/bin/bash
# qui remover
# soup 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

function _remove_qui() {
    users=($(_get_user_list))
    for user in ${users[@]}; do
        systemctl disable --now -q qui@${user}
        rm -rf /home/${user}/.config/qui
    done

    rm -f /etc/systemd/system/qui@.service
    rm -f /usr/bin/qui

    systemctl daemon-reload -q

    if [[ -f /install/.nginx.lock ]]; then
        rm -f /etc/nginx/apps/qui.conf
        rm -f /etc/nginx/conf.d/*.qui.conf

        systemctl reload nginx >> "$log" 2>&1
    fi

    rm /install/.qui.lock
}

_remove_qui
