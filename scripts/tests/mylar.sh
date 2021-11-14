#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin
#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

MYLAR_OWNER=$(swizdb get mylar/owner)
port=$(awk -F "=" '/http_port/ {print $2}' /home/$MYLAR_OWNER/.config/mylar/config.ini | tr -d ' ')

function _check_port_curl() {
    echo_progress_start "Checking if port $1 is reachable via curl"
    if [ "$1" -eq "$1" ] 2> /dev/null; then
        port=$1
    else
        port=$(get_port "$1") || {
            echo_warn "Couldn't guess port"
            return 1
        }
    fi
    extra_params="$2"
    # shellcheck disable=SC2086 # We want splitting on the extra params variable. So the warning is void here.
    curl -sSfLk $extra_params http://127.0.0.1:"$port/mylar" -o /dev/null || {
        echo_warn "Querying http://127.0.0.1:$port/mylar failed"
        echo
        return 1
    }
    echo_progress_done
}

check_service "mylar" || BAD=true
_check_port_curl "${port}" || BAD=true
check_nginx "mylar" || BAD=true

evaluate_bad "mylar"
