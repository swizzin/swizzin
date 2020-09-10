#!/bin/bash
#
# [ swizzin :: Install plexmediaserver package]
# Originally authored by: JMSolo for QuickBox
# Modifications to QuickBox package by: liara / PastaGringo
# Maintained and updated for swizzin by: liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Modifications for/by swizzin copyright (C) 2019 swizzin.ltd
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi
master=$(cut -d: -f1 < /root/.master.info)

echo "Please visit https://www.plex.tv/claim, login, copy your plex claim token to your clipboard and paste it here. This will automatically claim your server! Otherwise, you can leave this blank and to tunnel to the port instead."; read 'claim'

#versions=https://plex.tv/api/downloads/1.json
#wgetresults="$(wget "${versions}" -O -)"
#releases=$(grep -ioe '"label"[^}]*' <<<"${wgetresults}" | grep -i "\"distro\":\"ubuntu\"" | grep -m1 -i "\"build\":\"linux-ubuntu-x86_64\"")
#latest=$(echo ${releases} | grep -m1 -ioe 'https://[^\"]*')

echo "Installing plex keys and sources ... "
  wget -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | sudo apt-key add -
  echo "deb https://downloads.plex.tv/repo/deb public main" > /etc/apt/sources.list.d/plexmediaserver.list     
  echo

echo "Updating system ... "
  # TODO is this necessary?
  apt_install apt-transport-https --skip-update
  apt_update
  apt_install plexmediaserver
  echo

  if [[ ! -d /var/lib/plexmediaserver ]]; then
    mkdir -p /var/lib/plexmediaserver
  fi
  perm=$(stat -c '%U' /var/lib/plexmediaserver/)
  if [[ ! $perm == plex ]]; then
    chown -R plex:plex /var/lib/plexmediaserver
  fi
  usermod -a -G ${master} plex

if [[ -n $claim ]]; then
  sleep 5
  . /etc/swizzin/sources/functions/plex
  claimPlex ${claim}
fi

    systemctl restart plexmediaserver >/dev/null 2>&1

    touch /install/.plex.lock
    echo

echo "Plex Install Complete!"

