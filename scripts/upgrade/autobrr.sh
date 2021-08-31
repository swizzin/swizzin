#!/bin/bash
# autobrr upgrader
# ludviglundgren 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/autobrr
. /etc/swizzin/sources/functions/autobrr

if [[ ! -f /install/.autobrr.lock ]]; then
    echo_error "autobrr doesn't appear to be installed!"
    exit 1
fi

_restart_autobrr() {
    echo_progress_start "Restarting autobrr services"
    for user in $(_get_user_list); do
        # restart autobrr
        echo_log_only "Restarting autobrr for $user"
        systemctl try-restart "autobrr@${user}"
    done
    echo_progress_done "Service restarted"
}

autobrr_download_latest
_restart_autobrr

echo_success "autobrr upgraded"
