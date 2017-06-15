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
OUTTO="/srv/rutorrent/home/db/output.log"
HOSTNAME1=$(hostname -s)
PUBLICIP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
local_setup=/etc/QuickBox/setup/

echo "Setting up hostname for plex ... "
    echo -ne "ServerName ${HOSTNAME1}" | sudo tee /etc/apache2/conf-available/fqdn.conf >/dev/null 2>&1
    sudo a2enconf fqdn >> /dev/null 2>&1
    echo

echo "Setting up plex apache configuration ... "
  cp ${local_setup}templates/plex.conf.template /etc/apache2/sites-enabled/plex.conf
  chown www-data: /etc/apache2/sites-enabled/plex.conf
  a2enmod proxy >/dev/null 2>&1
  sed -i "s/PUBLICIP/${PUBLICIP}/g" /etc/apache2/sites-enabled/plex.conf


echo "Installing plex keys and sources ... "
    #wget -O - http://shell.ninthgate.se/packages/shell.ninthgate.se.gpg.key | apt-key add - #MODIFIED
    #echo "deb http://shell.ninthgate.se/packages/debian jessie main" > /etc/apt/sources.list.d/plexmediaserver.list #MODIFIED
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
    service apache2 reload >/dev/null 2>&1

    exit
