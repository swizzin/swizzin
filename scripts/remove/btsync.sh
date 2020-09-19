#!/bin/bash
#
# [Quick Box :: Remove Resilio Sync (BTSync) package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
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
if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
else
  OUTTO="/root/logs/swizzin.log"
fi

function _removeBTSync() {
  systemctl stop resilio-sync
  apt_remove --purge resilio-sync*
  deluser rslsync >>"${OUTTO}" 2>&1
  delgroup rslsync >>"${OUTTO}" 2>&1
  if [[ -d /home/rslsync ]]; then
    rm -rf /home/rslsync
  fi
  rm -rf /etc/systemd/system/resilio-sync.service
  rm -rf /home/${MASTER}/sync_folder
  rm /install/.btsync.lock
}

_removeBTSync
