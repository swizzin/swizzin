#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_nginx "rapidleech" || bad="true"

evaluate_bad
