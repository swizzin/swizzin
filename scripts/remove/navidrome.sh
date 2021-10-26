#!/bin/bash
# navidrome remover
# byte 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

function _remove_navidrome() {
    systemctl disable --now -q navidrome.service

    rm -f /etc/systemd/system/navidrome.service
    rm -rf /opt/navidrome
    rm -rf /var/lib/navidrome

    systemctl daemon-reload -q

    if [[ -f /install/.nginx.lock ]]; then
        rm -f /etc/nginx/apps/navidrome.conf
        
        systemctl reload nginx >> "$log" 2>&1
    fi

    rm /install/.navidrome.lock
}

_remove_navidrome
