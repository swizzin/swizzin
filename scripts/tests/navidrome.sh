#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "navidrome" || BAD=true
check_nginx "navidrome" || BAD=true

evaluate_bad "navidrome"
