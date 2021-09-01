#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

app_name="mylar"

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
    curl -sSfLk $extra_params http://127.0.0.1:"$port/$app_name" -o /dev/null || {
        echo_warn "Querying http://127.0.0.1:$port/$app_name failed"
        echo
        return 1
    }
    echo_progress_done
}

check_service "mylar" || BAD=true
_check_port_curl "$(swizdb get mylar/port)" || BAD=true
check_nginx "mylar" || BAD=true

evaluate_bad "mylar"
