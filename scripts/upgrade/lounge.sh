#!/usr/bin/env bash

if [[ ! -f /install/.lounge.lock ]]; then
    echo "lounge does not appear to be installed!"
    exit 1
fi

if [[ $(systemctl is-active lounge) == "active" ]]; then
    wasActive="true"
    echo_progress_start "Shutting down lounge"
    systemctl stop lounge
    echo_progress_done
fi

if ! npm update -g thelounge >> "$log"; then
    echo_error "Lounge failed to update, please investigate the logs"
fi

if [[ $wasActive = "true" ]]; then
    echo_progress_start "Restarting lounge"
    systemctl start lounge
    echo_progress_done
fi
