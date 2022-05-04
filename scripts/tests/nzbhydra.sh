#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

# run all functions, if one fails, mark as bad
check_service "nzbhydra" || BAD="true"
check_port "nzbhydra" || BAD="true"
# check_port_curl "nzbhydra" || BAD="true"
check_nginx "nzbhydra" || BAD="true"

evaluate_bad "nzbhydra"
