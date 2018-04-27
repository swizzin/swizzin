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
PUBLICIP=$(ip route get 8.8.8.8 | awk '{printf $7}')
DISTRO=$(lsb_release -is)
CODENAME=$(lsb_release -cs)
master=$(cat /root/.master.info | cut -d: -f1)

#versions=https://plex.tv/api/downloads/1.json
#wgetresults="$(wget "${versions}" -O -)"
#releases=$(grep -ioe '"label"[^}]*' <<<"${wgetresults}" | grep -i "\"distro\":\"ubuntu\"" | grep -m1 -i "\"build\":\"linux-ubuntu-x86_64\"")
#latest=$(echo ${releases} | grep -m1 -ioe 'https://[^\"]*')

echo "Installing plex keys and sources ... "
    wget -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | sudo apt-key add -
    if [[ $CODENAME =~ ("artful"|"bionic") ]]; then
      # Hacky work around until plex team fixes their repository. Will result in ignorable warnings in apt.
      echo "deb https://downloads.plex.tv/repo/deb/ public main" > /etc/apt/sources.list.d/plexmediaserver.list     
    else
      echo "deb https://downloads.plex.tv/repo/deb/ ./public main" > /etc/apt/sources.list.d/plexmediaserver.list

    fi
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
    usermod -a -G ${master} plex
    service plexmediaserver restart >/dev/null 2>&1
    touch /install/.plex.lock
    echo

echo "Plex Install Complete!" >>"${OUTTO}" 2>&1;
    sleep 5
    echo >>"${OUTTO}" 2>&1;
    echo >>"${OUTTO}" 2>&1;
    echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
    exit
