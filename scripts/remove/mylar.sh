#!/bin/bash
systemctl disable --now mylar
rm -rf /opt/Mylar
rm -rf /opt/.venv/mylar
if ask "Would you like to purge the config?"; then
    : rm -rf /home/$(swizdb get Mylar/owner)/.config/Mylar
else
    : break
fi
