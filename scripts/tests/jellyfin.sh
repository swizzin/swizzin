#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "jellyfin" || bad=true
check_port "jellyfin" || bad=true
check_nginx "jellyfin" || bad=true

evaluate_bad
