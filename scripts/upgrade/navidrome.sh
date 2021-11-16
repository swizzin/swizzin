#!/bin/bash
# navidrome upgrader
# byte 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/navidrome
. /etc/swizzin/sources/functions/navidrome

if [[ ! -f /install/.navidrome.lock ]]; then
    echo_error "navidrome doesn't appear to be installed!"
    exit 1
fi

_restart_navidrome() {
    systemctl try-restart "navidrome"
    echo_progress_done "Service restarted"
}

_navidrome_download_latest
_restart_navidrome

echo_success "navidrome upgraded"
