#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "vsftpd" || BAD=true
check_port "21" || BAD=true

evaluate_bad "vsftpd"
