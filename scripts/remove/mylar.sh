#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin
#

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

systemctl -q disable --now mylar

rm_if_exists /etc/systemd/system/mylar.service
rm_if_exists /opt/mylar
rm_if_exists /opt/.venv/mylar
rm_if_exists /install/.mylar.lock
rm_if_exists "/home/$(swizdb get mylar/owner)/.config/mylar"

swizdb clear mylar/owner

if [[ -f /install/.nginx.lock ]]; then
    rm_if_exists /etc/nginx/apps/mylar.conf
    systemctl -q reload nginx.service
fi
