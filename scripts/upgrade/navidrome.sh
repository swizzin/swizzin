#!/bin/bash
# navidrome upgrader
# byte 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/autobrr
. /etc/swizzin/sources/functions/navidrome

if [[ ! -f /install/.navidrome.lock ]]; then
    echo_error "navidrome doesn't appear to be installed!"
    exit 1
fi

_restart_navidrome() {
    for user in "${users[@]}"; do
        # restart navidrome
        systemctl try-restart "navidrome"
    done
    echo_progress_done "Service restarted"
}

navidrome_download_latest
_restart_navidrome

echo_success "navidrome upgraded"
