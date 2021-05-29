#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "jackett@$(_get_master_user)" || bad=true
check_port "jackett" || bad=true
check_nginx "jackett" || bad=true

evaluate_bad
