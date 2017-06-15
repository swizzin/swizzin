#!/bin/bash
#
# [Quick Box :: Install systemd services]
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

function _removecron() {
for i in "${users[@]}"; do
  sudo -u ${i} crontab -l | sed '/.startup/d' | crontab -u ${i} -  > /dev/null 2>&1
done
rm /install/.cron.lock
}

function _installd() {
arr=()
locks=($(find ${local_setup}templates/sysd -type f -printf "%f\n" | cut -d "." -f 1 ))

for i in "${locks[@]}"; do
  app=$i
  if [[ $i == deluged ]] || [[ $i == deluge-web ]]; then
    app=deluge
  fi
  if [[ -f /install/.$app.lock ]]; then
    arr+=("$i")
    pkill $i
    cp ${local_setup}templates/sysd/$i.template /etc/systemd/system/$i@.service
    if [[ $i == autodlirssi ]]; then
    mv /etc/systemd/system/autodlirssi@.service /etc/systemd/system/irssi@.service
    fi
  fi
done
  for l in sonarr sickrage jackett couchpotato; do
    if [[ -f /etc/init.d/$l ]]; then update-rc.d -f $l remove; fi
    if [[ -f /etc/init.d/$l ]]; then service $l stop; fi
    if [[ -f /etc/init.d/$l ]]; then rm /etc/init.d/$l; fi
  done
  for i in "${arr[@]}"; do
   if [[ $i == autodlirssi ]]; then
     i=irssi
   fi
    systemctl enable "${i}@${master}" > /dev/null 2>&1
    systemctl restart "${i}@${master}" > /dev/null 2>&1
  done
for u in "${users[@]}"; do
  if [[ ! $u == $master ]]; then
    for p in rtorrent irssi deluged delugeweb; do
      if [[ $(cat /home/${u}/.startup | grep -i -m 1 ${p} | cut -d "=" -f 2) == yes ]]; then
        if [[ $p == delugeweb ]]; then p=deluge-web; fi
        systemctl enable "${p}@${u}"  > /dev/null 2>&1
        systemctl start "${p}@${u}"  > /dev/null 2>&1
      fi
    done
  fi
done
echo "systemd installation complete! "
echo "Reboot recommended ... "
}

local_setup=/etc/QuickBox/setup/
users=($(cat /etc/htpasswd | cut -d ":" -f 1))
master=($(cat /srv/rutorrent/home/db/master.txt))
_removecron
_installd
