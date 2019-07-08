#!/bin/bash
# Uninstall for deluge package on swizzin
# [swizzin :: Uninstaller for Deluge package]
# Author: liara
#
# swizzin Copyright (C) 2019
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
users=($(cat /etc/htpasswd | cut -d ":" -f 1))
for u in ${users}; do
  systemctl disable --now deluged@$u > /dev/null 2>&1
  systemctl disable --now deluge-web@$u > /dev/null 2>&1
  rm -rf /home/${u}/.config/deluge
done

rm /etc/systemd/system/deluged@.service
rm /etc/systemd/system/deluge-web@.service
dpkg -r libtorrent
dpkg -r libtorrent-rasterbar
#dpkg -r deluge
apt-get purge -y deluge> /dev/null 2>&1
apt-get purge -y deluge-web deluge-console > /dev/null 2>&1

rm -rf /usr/lib/python2.7/dist-packages/deluge*

rm /install/.deluge.lock
