#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "jellyfin" || BAD=true
check_port "jellyfin" || BAD=true
check_nginx "jellyfin" || BAD=true

evaluate_bad "jellyfin"
