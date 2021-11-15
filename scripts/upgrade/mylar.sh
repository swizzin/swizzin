#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin
if [[ -f /install/.mylar.lock ]]; then
    systemctl stop mylar
    MYLAR_OWNER=$(swizdb get mylar/owner)
    echo_progress_start "Pulling new commits"
    git -C /opt/mylar checkout origin/master >> $log 2>&1 ||
        {
            echo_warn "Unclean repo detected, resetting current branch."
            git -C /opt/mylar reset --hard >> $log 2>&1
            git -C /opt/mylar checkout master >> $log 2>&1
        }
    {
        #shellcheck disable=SC2129
        git -C /opt/mylar fetch --all --tags --prune >> $log 2>&1
        git -C /opt/mylar reset --hard master >> $log 2>&1
    } || {
        echo_error "Failed to update from git"
        exit 1
    }
    echo_progress_done

    /opt/.venv/mylar/bin/pip install --upgrade pip >> ${log} 2>&1
    /opt/.venv/mylar/bin/pip install -r /opt/mylar/requirements.txt >> ${log} 2>&1
    chown -R $MYLAR_OWNER: /opt/mylar/
    chown -R $MYLAR_OWNER: /opt/.venv/mylar/

    echo_progress_start "Restarting Mylar"
    systemctl restart -q mylar
    echo_progress_done "Done!"
fi
