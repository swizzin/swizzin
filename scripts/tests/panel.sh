#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "panel" || bad=true
check_port_curl "panel" || bad=true
check_nginx "" || bad=true

evaluate_bad
