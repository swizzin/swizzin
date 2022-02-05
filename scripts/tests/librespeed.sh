#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_nginx "librespeed" || BAD="true"

evaluate_bad "librespeed"
