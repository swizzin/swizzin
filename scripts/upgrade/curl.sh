#!/bin/bash
# Upgrade curl to bypass the bug in Debian 10. Can be used on any system however, but the benefit is to Buster users most

. /etc/swizzin/sources/functions/curl
configure_curl
build_cares
build_curl
