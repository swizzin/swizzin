#!/bin/bash
#
# [Quick Box :: Install plexmediaserver package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/PastaGringo/scripts
# LOCAL REPOS        :
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   PastaGringo
# URL                :   https://plaza.quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi
HOSTNAME1=$(hostname -s)
PUBLICIP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')

echo "Installing plex keys and sources ... "
      wget -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | sudo apt-key add -
    echo "deb https://downloads.plex.tv/repo/deb/ public main" > /etc/apt/sources.list.d/plexmediaserver.list
    echo

echo "Updating system ... "
    apt-get install apt-transport-https -y >/dev/null 2>&1
    apt-get -y update >/dev/null 2>&1
    apt-get install -o Dpkg::Options::="--force-confold" -y -f plexmediaserver >/dev/null 2>&1
    #DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get -q -y -o -f "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install plexmediaserver >/dev/null 2>&1
    echo

    if [[ ! -d /var/lib/plexmediaserver ]]; then
      mkdir -p /var/lib/plexmediaserver
    fi
    perm=$(stat -c '%U' /var/lib/plexmediaserver/)
    if [[ ! $perm == plex ]]; then
      chown -R plex:plex /var/lib/plexmediaserver
    fi
    service plexmediaserver restart >/dev/null 2>&1
    touch /install/.plex.lock
    echo

echo "Plex Install Complete!" >>"${OUTTO}" 2>&1;
    sleep 5
    echo >>"${OUTTO}" 2>&1;
    echo >>"${OUTTO}" 2>&1;
    echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
    exit
