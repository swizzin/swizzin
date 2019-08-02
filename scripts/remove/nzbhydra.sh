#!/bin/bash
#
# [Quick Box :: Remove nzbhydra package]
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
  systemctl stop nzbhydra@${MASTER}
  systemctl disable nzbhydra@${MASTER}
  rm /etc/systemd/system/nzbhydra@.service
if [[ -f /etc/init.d/nzbhydra ]]; then
  service nzbhydra stop
  rm /etc/init.d/nzbhydra
  rm /etc/default/nzbhydra
fi
rm -rf /home/${MASTER}/nzbhydra
rm -f /etc/nginx/apps/nzbhydra.conf
rm /install/.nzbhydra.lock
service nginx reload
  echo -n "Verifying nzbhydra removal from /home/$MASTER."
  echo ""
  echo "NZBhydra Uninstall Complete. App data is not removed. To remove run the following command: rm -rf /home/$MASTER/.nzbhyra."
  echo ""
  echo "You may reinstall at any time by running [installpackage-nzbhydra]."