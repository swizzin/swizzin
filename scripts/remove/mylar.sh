#!/bin/bash
# Mylar installer for Swizzin
# Author: Brett
# Copyright (C) 2021 Swizzin
systemctl disable --now mylar
rm -rf /etc/systemd/system/mylar.service
rm -rf /opt/mylar
rm -rf /opt/.venv/mylar
rm -rf /install/.mylar.lock
rm -rf /home/$(swizdb get mylar/owner)/.config/mylar
swizdb clear mylar/owner
