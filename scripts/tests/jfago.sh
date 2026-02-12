#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "jfago" || BAD=true
check_port "8056" || BAD=true
check_nginx "jfa-go" || BAD=true

evaluate_bad "jfago"
