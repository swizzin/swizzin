#!/bin/bash
#
# [Quick Box :: Install Jackett package]
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

DISTRO=$(lsb_release -is)
CODENAME=$(lsb_release -cs)
OUTTO=/srv/rutorrent/home/db/output.log
username=$(cat /srv/rutorrent/home/db/master.txt)
local_setup=/etc/QuickBox/setup/

echo "Setting up emby apache configuration ... " >>"${OUTTO}" 2>&1;
  cp ${local_setup}templates/emby.conf.template /etc/apache2/sites-enabled/emby.conf
  chown www-data /etc/apache2/sites-enabled/emby.conf
  a2enmod proxy >/dev/null 2>&1

echo "Installing emby keys and sources ... " >>"${OUTTO}" 2>&1;
  if [[ $DISTRO == Debian ]]; then
    echo 'deb http://download.opensuse.org/repositories/home:/emby/Debian_8.0/ /' > /etc/apt/sources.list.d/emby-server.list
    wget --quiet http://download.opensuse.org/repositories/home:emby/Debian_8.0/Release.key -O - | apt-key add - > /dev/null 2>&1
  elif [[ $CODENAME == yakkety ]]; then
    sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/emby/xUbuntu_16.10/ /' > /etc/apt/sources.list.d/emby-server.list"
    wget --quiet http://download.opensuse.org/repositories/home:emby/xUbuntu_16.10/Release.key -O - | apt-key add - > /dev/null 2>&1
  elif [[ $CODENAME == xenial ]]; then
    sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/emby/xUbuntu_16.04/ /' > /etc/apt/sources.list.d/emby-server.list"
    wget --quiet http://download.opensuse.org/repositories/home:emby/xUbuntu_16.04/Release.key -O - | apt-key add - > /dev/null 2>&1
  elif [[ $CODENAME == wily ]]; then
    sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/emby/xUbuntu_15.10/ /' > /etc/apt/sources.list.d/emby-server.list"
    wget --quiet http://download.opensuse.org/repositories/home:emby/xUbuntu_15.10/Release.key -O - | apt-key add - > /dev/null 2>&1
  fi

echo "Updating system & installing emby server ... " >>"${OUTTO}" 2>&1;
    apt-get -y update >/dev/null 2>&1
    apt-get install -y --allow-unauthenticated -f emby-server >/dev/null 2>&1
    echo
    sleep 5

    if [[ -f /etc/emby-server.conf ]]; then
      echo "EMBY_USER="${username}"" >> /etc/emby-server.conf
      echo "EMBY_GROUP="${username}"" >> /etc/emby-server.conf
    fi

    systemctl restart emby-server >/dev/null 2>&1
    touch /install/.emby.lock
    echo

echo "Emby Install Complete!" >>"${OUTTO}" 2>&1;
    sleep 5
    echo >>"${OUTTO}" 2>&1;
    echo >>"${OUTTO}" 2>&1;
    echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
    service apache2 reload > /dev/null 2>&1

    exit
