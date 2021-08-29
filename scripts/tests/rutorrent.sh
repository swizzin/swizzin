#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_nginx "rutorrent" || BAD="true"

evaluate_bad "rutorrent"
