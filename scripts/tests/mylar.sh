#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "mylar" || BAD=true
check_port_curl "mylar" || BAD=true
check_nginx "mylar" || BAD=true

evaluate_bad "mylar"
