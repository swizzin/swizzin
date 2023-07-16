#!/bin/bash

if [[ -f /install/.deluge.lock ]]; then
    if grep -q ExecStop /etc/systemd/system/deluged@.service > /dev/null 2>&1; then
        sed -i '/ExecStop/d' /etc/systemd/system/deluged@.service
        reloadsys=true
    fi
    if grep -q ExecStop /etc/systemd/system/deluge-web@.service > /dev/null 2>&1; then
        sed -i '/ExecStop/d' /etc/systemd/system/deluge-web@.service
        reloadsys=true
    fi
    if [[ $reloadsys == "true" ]]; then
        echo_progress_start "Updating Deluge systemd service files"
        systemctl daemon-reload
        echo_progress_done
    fi
fi
