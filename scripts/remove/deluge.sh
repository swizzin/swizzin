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
users=($(cut -d: -f1 < /etc/htpasswd))
for u in ${users}; do
  systemctl disable --now deluged@$u > /dev/null 2>&1
  systemctl disable --now deluge-web@$u > /dev/null 2>&1
  rm -rf /home/${u}/.config/deluge
  rm -rf /home/${u}/dwatch
done

rm /etc/systemd/system/deluged@.service
rm /etc/systemd/system/deluge-web@.service
apt_remove --purge deluge*

if [[ -f /install/.nginx.lock ]]; then
  rm -f /etc/nginx/apps/deluge.conf > /dev/null 2>&1
  rm -f /etc/nginx/apps/dindex.conf > /dev/null 2>&1
  rm -f /etc/nginx/conf.d/*.deluge.conf > /dev/null 2>&1
fi

rm -rf /usr/lib/python2.7/dist-packages/deluge*

rm /install/.deluge.lock
rm /install/.delugeweb.lock

if [[ ! -f /install/.qbittorrent.lock ]]; then
    bash /etc/swizzin/scripts/remove/libtorrent.sh
fi
