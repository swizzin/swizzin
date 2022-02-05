#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "plexmediaserver" || BAD=true
check_port "32400" || BAD=true

evaluate_bad "plex"
