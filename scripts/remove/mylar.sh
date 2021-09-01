#!/bin/bash
. /etc/swizzin/sources/globals.sh
systemctl disable --now mylar
rm -rf /opt/Mylar
rm -rf /opt/.venv/mylar
rm -rf /install/.mylar.lock
if ask "Would you like to purge the config?"; then
    : rm -rf /home/$(swizdb get Mylar/owner)/.config/Mylar
    swizdb clear Mylar/owner
else
    : break
fi
