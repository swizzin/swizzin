#!/bin/bash
#
# [Quick Box :: Uninstaller for Rapidleech package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO
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
OUTTO="/root/quick-box.log"

function _removeRapidleech() {
  sudo rm -r  /home/"${MASTER}"/rapidleech
  sudo rm /etc/nginx/apps/${MASTER}.rapidleech.conf
  sudo rm /install/.rapidleech.lock
  service nginx reload
}

_removeRapidleech
