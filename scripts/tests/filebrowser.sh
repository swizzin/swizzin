#!/bin/bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "filebrowser" || BAD=true
check_port "filebrowser" || BAD=true
check_port_curl "filebrowser" "" "filebrowser/login" "https://" || BAD=true
check_nginx "filebrowser" || BAD=true

evaluate_bad
