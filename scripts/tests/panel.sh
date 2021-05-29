#!/usr/bin/env bash

#shellcheck source=scripts/tests/basetest.sh
. /etc/swizzin/scripts/tests/basetest.sh

check_service "panel" || bad=true
check_nginx "" || bad=true

evaluate_bad
