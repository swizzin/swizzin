#!/bin/bash
#
# [Quick Box :: Remove couchpotato package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | liara
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

MASTER=$(cut -d: -f1 < /root/.master.info)
  systemctl disable couchpotato@*
  systemctl stop couchpotato@*
  rm /etc/systemd/system/couchpotato@.service
if [[ -f /etc/init.d/couchpotato ]]; then
  service couchpotato stop
  rm /etc/init.d/couchpotato
  rm /etc/default/couchpotato
fi
rm -rf /home/${MASTER}/.couchpotato
rm -f /etc/nginx/apps/couchpotato.conf
service nginx reload
rm /install/.couchpotato.lock
