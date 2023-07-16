#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

echo_log_only "Checking nginx config"
nginx -t > /dev/null 2>&1 || {
    nginx -t
    echo_warn "nginx config is invalid"
    BAD="true"
}

check_service "nginx" || BAD="true"
check_port "443"

evaluate_bad "nginx"
