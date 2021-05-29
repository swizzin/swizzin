#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "plexmediaserver" || bad=true
# check_port "32400" || bad=true

evaluate_bad
