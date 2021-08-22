#!/usr/bin/env bash
# LazyLibrarian test script for swizzin
# Author: Aethaeran 2021
# GPLv3

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

app_name="lazylibrarian"

check_port_curl_lazylib() {
    echo_progress_start "Checking if port $1 is reachable via curl"
    # override necessary for baseurl inclusion
    curl -sSfLk http://127.0.0.1:"$port/$app_name" -o /dev/null || {
        echo_warn "Querying http://127.0.0.1:$port/$app_name failed"
        echo
        return 1
    }
    echo_progress_done
}

check_service "$app_name" || BAD="true"
check_port 5299 || BAD="true"
check_port_curl_lazylib 5299 || BAD="true"
check_nginx "$app_name" || BAD="true"

evaluate_bad
