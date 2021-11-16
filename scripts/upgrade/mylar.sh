#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin

if [[ -f /install/.mylar.lock ]]; then
    systemctl -q stop mylar
    mylar_owner="$(swizdb get mylar/owner)"
    echo_progress_start "Pulling new commits"

    git -C /opt/mylar checkout origin/master &>> "${log}" || {
        echo_warn "Unclean repo detected, resetting current branch."
        git -C /opt/mylar reset --hard &>> "${log}"
        git -C /opt/mylar checkout master &>> "${log}"
    }

    git -C /opt/mylar fetch --all --tags --prune &>> "${log}"

    git -C /opt/mylar reset --hard master &>> "${log}" || {
        echo_error "Failed to update from git"
        exit 1
    }

    echo_progress_done

    /opt/.venv/mylar/bin/pip install --upgrade pip &>> "${log}"
    /opt/.venv/mylar/bin/pip install -r /opt/mylar/requirements.txt &>> "${log}"
    chown -R "${mylar_owner}": /opt/mylar/
    chown -R "${mylar_owner}": /opt/.venv/mylar/

    echo_progress_start "Restarting Mylar"
    systemctl -q restart mylar
    echo_progress_done "Done!"
fi
