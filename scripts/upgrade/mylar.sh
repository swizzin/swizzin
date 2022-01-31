#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin

if [[ -f /install/.mylar.lock ]]; then
    #shellcheck source=sources/functions/mylar
    . /etc/swizzin/sources/functions/mylar
    systemctl -q stop mylar
    echo_progress_start "Grabbing the latest Mylar"
    _download_latest
    echo_progress_done
    echo_progress_start "Restarting Mylar"
    systemctl daemon-reload -q
    systemctl -q restart mylar
    echo_progress_done "Done!"
fi
