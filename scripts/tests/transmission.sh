#!/usr/bin/env bash

#shellcheck source=scripts/tests/basetest.sh
. /etc/swizzin/scripts/tests/basetest.sh

master="$(_get_master_username)"
check_service "transmission@$master" || bad=true
check_port "transmission" || bad=true
check_nginx "transmission" || bad=true

evaluate_bad
