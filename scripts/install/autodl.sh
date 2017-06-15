#!/bin/bash
#
# [Quick Box :: Install AutoDL-IRSSI package]
#
# QUICKLAB REPOS
# QuickLab _ packages  :   https://github.com/QuickBox/quickbox_packages
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
#   QuickBox.IO does not grant the end-user the right to distribute this
#   code in a means to supply commercial monetization. If you would like
#   to include QuickBox in your commercial project, write to echo@quickbox.io
#   with a summary of your project as well as its intended use for moentization.
#
MASTER=$(cat /srv/rutorrent/home/db/master.txt)
IRSSIIP=$(curl -s http://ipecho.net/plain || curl -s http://ifconfig.me/ip ; echo)

OUTTO="/root/quick-box.log"
local_setup=/etc/QuickBox/setup/


function _installautodl() {
  rutorrent="/srv/rutorrent/";
  PLUGINVAULT="/etc/quickbox/plugins/"; cd "${rutorrent}plugins"
  PLUGIN="autodl-irssi"
  users=($(cat /etc/htpasswd | cut -d ":" -f 1))
    for i in $PLUGIN; do
      cp -R "${PLUGINVAULT}$i" .
      chown -R www-data: ${rutorrent}plugins/$PLUGIN
    done
    for u in "${users[@]}"; do
      IRSSI_PASS=$(_string)
      IRSSI_PORT=$(shuf -i 20000-61000 -n 1)
      mkdir -p "/home/${u}/.irssi/scripts/autorun/" >>"${OUTTO}" 2>&1
      cd "/home/${u}/.irssi/scripts/"
      wget -qO autodl-irssi.zip https://github.com/autodl-community/autodl-irssi/releases/download/community-v1.60/autodl-irssi-community-v1.60.zip >/dev/null 2>&1
      unzip -o autodl-irssi.zip >>"${OUTTO}" 2>&1
      rm autodl-irssi.zip
      cp autodl-irssi.pl autorun/
      mkdir -p "/home/${u}/.autodl" >>"${OUTTO}" 2>&1
      touch "/home/${u}/.autodl/autodl.cfg"
cat >"/home/${u}/.autodl/autodl2.cfg"<<ADC
[options]
gui-server-port = ${IRSSI_PORT}
gui-server-password = ${IRSSI_PASS}
ADC

echo -n "\$autodlport = \"$IRSSI_PORT\";" /srv/rutorrent/conf/users/${u}/config.php
echo -n "\$autodlPassword = \"$IRSSI_PASS\";" /srv/rutorrent/conf/users/${u}/config.php
done

_installautodl
