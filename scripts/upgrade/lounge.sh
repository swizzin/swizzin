#!/usr/bin/env bash

if [[ ! -f /install/.lounge.lock ]]; then
    echo "lounge does not appear to be installed!"
    exit 1
fi

if ! npm outdated --global thelounge >> $log 2>&1; then # `npm outdated <package>` returns 0 if package is up to date, and 1 if an update is available
    echo_progress_start "Shutting down and upgrading lounge"
    if [[ $(systemctl is-active lounge) == "active" ]]; then
        wasActive="true"
        systemctl stop lounge
    fi

    if ! npm update -g thelounge >> "$log"; then
        echo_error "Lounge failed to update, please investigate the logs"
    fi

    if [[ $wasActive = "true" ]]; then
        systemctl start lounge
    fi
    echo_progress_done "Lounge upgraded and restarted"
else
    echo_info "Lounge is up to date"
fi
