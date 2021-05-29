#!/usr/bin/env bash

#shellcheck source=scripts/tests/basetest.sh
. /etc/swizzin/scripts/tests/basetest.sh

echo_progress_start "Checking nginx config"
nginx -t || {
    echo_warn "nginx config is invalid"
    bad="true"
}

echo_progress_done

check_service "nginx" || bad="true"
# check_nginx "" || bad="true"

evaluate_bad
