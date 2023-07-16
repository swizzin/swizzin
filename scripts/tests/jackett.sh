#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "jackett@$(_get_master_username)" || BAD=true
check_port_curl "jackett" || BAD=true
check_nginx "jackett" || BAD=true

evaluate_bad "jackett"
