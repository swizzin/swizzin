#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
if [[ -f /install/.mylar.lock ]]; then

    cd /opt/mylar || {
        echo_warn "Failed to cd into /opt/mylar."
    }
    #git reset HEAD --hard
    echo_progress_start "Pulling new commits"
    git pull >> ${log} 2>&1 || {
        echo_warn "Pull failed."
    }
    echo_progress_done "Commits pulled"
    echo_progress_start "Checking pip for new depends"
    if ! /opt/.venv/mylar/bin/python /opt/mylar/tests/test_requirements.py >> ${log} 2>&1; then
        /opt/.venv/mylar/bin/pip install -r /opt/mylar/requirements.txt >> ${log} 2>&1
    fi
    echo_progress_done "Depends up-to-date"
    echo_progress_start "Restarting Mylar"
    systemctl restart mylar
    echo_progress_done "Done!"
fi
