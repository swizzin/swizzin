#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "panel" || BAD=true
check_port_curl "panel" || BAD=true
check_nginx "" || BAD=true

evaluate_bad "panel"
