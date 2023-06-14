#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "audiobookshelf" || BAD=true
check_port_curl "13378" || BAD=true

evaluate_bad
