#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "lounge" || BAD=true
check_port_curl "lounge" || BAD=true
check_nginx "irc" || BAD=true

evaluate_bad "lounge"
