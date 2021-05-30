#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "lounge" || bad=true
check_port_curl "lounge" || bad=true
check_nginx "irc" || bad=true

evaluate_bad
