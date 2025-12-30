#!/bin/bash
# shinkro upgrader
# 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/shinkro
. /etc/swizzin/sources/functions/shinkro

if [[ ! -f /install/.shinkro.lock ]]; then
    echo_error "shinkro doesn't appear to be installed!"
    exit 1
fi

_restart_shinkro() {
    echo_progress_start "Restarting shinkro services"
    for user in $(_get_user_list); do
        # restart shinkro
        echo_log_only "Restarting shinkro for $user"
        systemctl try-restart "shinkro@${user}"
    done
    echo_progress_done "Service restarted"
}

shinkro_download_latest
_restart_shinkro

echo_success "shinkro upgraded"
