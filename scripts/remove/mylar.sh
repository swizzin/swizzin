#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin
#
. /etc/swizzin/sources/functions/utils

systemctl disable --now mylar
rm_if_exists /etc/systemd/system/mylar.service
rm_if_exists /opt/mylar
rm_if_exists /opt/.venv/mylar
rm_if_exists /install/.mylar.lock
rm_if_exists /home/$(swizdb get mylar/owner)/.config/mylar
swizdb clear mylar/owner
