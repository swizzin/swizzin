#!/bin/bash
# autobrr remover
# ludviglundgren 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

function _remove_autobrr() {
    users=($(_get_user_list))
    for user in ${users[@]}; do
        systemctl disable --now -q autobrr@${user}
        rm -rf /home/${user}/.config/autobrr
    done

    rm -f /etc/systemd/system/autobrr@.service
    rm -f /usr/bin/autobrr
    rm -f /usr/bin/autobrrctl

    systemctl daemon-reload -q

    if [[ -f /install/.nginx.lock ]]; then
        rm -f /etc/nginx/apps/autobrr.conf
        rm -f /etc/nginx/conf.d/*.autobrr.conf

        systemctl reload nginx >> "$log" 2>&1
    fi

    rm /install/.autobrr.lock
}

_remove_autobrr
