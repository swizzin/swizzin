#!/bin/bash
# autobrr upgrader
# ludviglundgren 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ ! -f /install/.autobrr.lock ]]; then
    echo_error "autobrr doesn't appear to be installed!"
    exit 1
fi

_restart_autobrr() {
    for user in "${users[@]}"; do
        # restart autobrr
        systemctl try-restart "autobrr@${user}"
    done
    echo_progress_done "Service restarted"
}

autobrr_download_latest
_restart_autobrr

echo_success "autobrr upgraded"
