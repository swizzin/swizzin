#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "vsftpd" || bad=true
check_port "21" || bad=true

evaluate_bad
