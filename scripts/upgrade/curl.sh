#!/bin/bash
# Upgrade curl to bypass the bug in Debian 10. Can be used on any system however, but the benefit is to Buster users most

. /etc/swizzin/sources/functions/curl
build_cares
build_curl

echo_info "An up-to-date version of curl has been installed to /usr/local/bin. Please be aware that curl may show an older version of curl until you log out and back in"
