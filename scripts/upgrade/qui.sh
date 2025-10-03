#!/bin/bash
# qui upgrader
# soup 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/qui
. /etc/swizzin/sources/functions/qui

if [[ ! -f /install/.qui.lock ]]; then
    echo_error "qui doesn't appear to be installed!"
    exit 1
fi

_restart_qui() {
    echo_progress_start "Restarting qui services"
    for user in $(_get_user_list); do
        # restart qui
        echo_log_only "Restarting qui for $user"
        systemctl try-restart "qui@${user}"
    done
    echo_progress_done "Service restarted"
}

qui_download_latest
_restart_qui

echo_success "qui upgraded"
