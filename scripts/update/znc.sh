#!/bin/bash

if [[ -f /install/.znc.lock ]]; then
    # shellcheck source=sources/functions/letsencrypt
    . /etc/swizzin/sources/functions/letsencrypt
    # Check if using tailnet address in default config, else use LE
    if grep -q ".ts.net" "/etc/nginx/sites-enabled/default"; then
        ts_znc_hook
    else
        le_znc_hook
    fi

    if [[ ! -s /install/.znc.lock ]]; then
        echo_progress_start "Updating ZNC config"
        echo "$(grep Port /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" > /install/.znc.lock
        echo "$(grep SSL /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" >> /install/.znc.lock
        echo_progress_done
    fi
fi
