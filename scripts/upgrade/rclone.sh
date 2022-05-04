!/bin/bash
# rclone upgrader
# byte 2022 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/navidrome
. /etc/swizzin/sources/functions/rclone

if [[ ! -f /install/.rclone.lock ]]; then
    echo_error "rclone doesn't appear to be installed!"
    exit 1
fi

_restart_rclone() {
    systemctl try-restart "rclone@"
    echo_progress_done "Service restarted"
}

_rclone_download_latest
_restart_rclone

echo_success "rclone upgraded"
