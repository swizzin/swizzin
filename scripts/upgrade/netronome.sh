#!/bin/bash
# netronome upgrader
# soup 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/netronome
. /etc/swizzin/sources/functions/netronome

if [[ ! -f /install/.netronome.lock ]]; then
    echo_error "netronome doesn't appear to be installed!"
    exit 1
fi

_restart_netronome() {
    echo_progress_start "Restarting netronome services"
    for user in $(_get_user_list); do
        # restart netronome
        echo_log_only "Restarting netronome for $user"
        systemctl try-restart "netronome@${user}"
    done
    echo_progress_done "Service restarted"
}

netronome_download_latest
_restart_netronome

echo_success "netronome upgraded"
