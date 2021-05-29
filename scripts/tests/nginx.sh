#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

echo_progress_start "Checking nginx config"
nginx -t > /dev/null 2>&1 || {
    nginx -t
    echo_warn "nginx config is invalid"
    bad="true"
}

echo_progress_done

check_service "nginx" || bad="true"
# check_nginx "" || bad="true"

evaluate_bad
