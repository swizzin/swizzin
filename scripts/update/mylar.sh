#!/bin/bash
#
# Mylar Updater
# Author: Brett
# Copyright (C) 2022 Swizzin

if [[ -f /install/.mylar.lock ]]; then
    #shellcheck source=sources/functions/mylar
    . /etc/swizzin/sources/functions/mylar
    mylar_owner="$(swizdb get mylar/owner)"
    if sudo -u ${mylar_owner} git -C /opt/mylar rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo_progress_start "Updating Mylar"
        rm -rf /opt/mylar
        _download_latest
        echo_progress_done
    fi
    if ! grep "forking" /etc/systemd/system/mylar.service > /dev/null 2>&1; then
        echo_progress_start "Updating Mylar systemd service file with forking"
        mylar_owner=$(swizdb get mylar/owner)
        _service
        systemctl daemon-reload -q
        systemctl try-restart mylar
        echo_progress_done
    fi
fi
