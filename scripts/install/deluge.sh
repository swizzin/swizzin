#!/bin/bash
#
# [Quick Box :: Install Deluge package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | lizaSB
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2016
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################
function _string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15 ; }
#################################################################################

OUTTO=/srv/rutorrent/home/db/output.log
local_setup=/etc/QuickBox/setup/
local_packages=/etc/QuickBox/packages/
username=$(cat /srv/rutorrent/home/db/master.txt)
passwd=$(cat /root/${username}.info | cut -d ":" -f 3 | cut -d "@" -f 1)
ip=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
n=$RANDOM
DPORT=$((n%59000+10024))
DWPORT=$(shuf -i 10001-11000 -n 1)
#DWSALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
DWSALT=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)

function _installDeluge1() {
  sudo apt-get -y update >/dev/null 2>&1
  sudo apt-get -y install deluged deluge-web >/dev/null 2>&1
  systemctl stop deluged >/dev/null 2>&1
  update-rc.d deluged remove >/dev/null 2>&1
  rm /etc/init.d/deluged >/dev/null 2>&1
}
function _installDeluge2() {
  DWP=$(python ${local_packages}system/deluge.Userpass.py ${passwd} ${DWSALT})
  DUDID=$(python ${local_packages}system/deluge.addHost.py)
  mkdir -p /home/${username}/.config/deluge/
  printf "${username}:${passwd}" > /root/${username}.info.db
  udb=$(cat /root/$username.info.db)
  chmod 755 /home/${username}/.config
  chmod 755 /home/${username}/.config/deluge
  cp ${local_setup}templates/core.conf.template /home/${username}/.config/deluge/core.conf
  cp ${local_setup}templates/web.conf.template /home/${username}/.config/deluge/web.conf
  cp ${local_setup}templates/hostlist.conf.1.2.template /home/${username}/.config/deluge/hostlist.conf.1.2
  sed -i "s/USERNAME/${username}/g" /home/${username}/.config/deluge/core.conf
  sed -i "s/DPORT/${DPORT}/g" /home/${username}/.config/deluge/core.conf
  sed -i "s/XX/${ip}/g" /home/${username}/.config/deluge/core.conf
  sed -i "s/DWPORT/${DWPORT}/g" /home/${username}/.config/deluge/web.conf
  sed -i "s/DWSALT/${DWSALT}/g" /home/${username}/.config/deluge/web.conf
  sed -i "s/DWP/${DWP}/g" /home/${username}/.config/deluge/web.conf
  sed -i "s/DUDID/${DUDID}/g" /home/${username}/.config/deluge/hostlist.conf.1.2
  sed -i "s/DPORT/${DPORT}/g" /home/${username}/.config/deluge/hostlist.conf.1.2
  sed -i "s/USERNAME/${username}/g" /home/${username}/.config/deluge/hostlist.conf.1.2
  sed -i "s/PASSWD/${passwd}/g" /home/${username}/.config/deluge/hostlist.conf.1.2
  echo "${udb}:10" > /home/${username}/.config/deluge/auth
  mkdir -p /home/${username}/.config/deluge/plugins
  if [[ ! -f /home/${username}/.config/deluge/plugins/ltConfig-0.2.5.0-py2.7.egg ]]; then
    cd /home/${username}/.config/deluge/plugins/
    wget -q https://github.com/ratanakvlun/deluge-ltconfig/releases/download/v0.2.5.0/ltConfig-0.2.5.0-py2.7.egg
  fi
}
function _installDeluge3() {
  chown -R ${username}.${username} /home/${username}/.config/
  mkdir /home/${username}/dwatch
  chown ${username}: /home/${username}/dwatch
  mkdir -p /home/${username}/torrents/deluge
  chown ${username}: /home/${username}/torrents/deluge
  touch /install/.deluge.lock
}
function _installDeluge4() {
  #cp "${local_setup}"templates/startup.template /home/"${username}"/.startup
  #sed -i 's/DELUGEWEB_CLIENT=no/DELUGEWEB_CLIENT=yes/g' /home/"${username}"/.startup
  #sed -i 's/DELUGED_CLIENT=no/DELUGED_CLIENT=yes/g' /home/"${username}"/.startup
  cp ${local_setup}templates/sysd/deluged.template /etc/systemd/system/deluged@.service
  cp ${local_setup}templates/sysd/deluge-web.template /etc/systemd/system/deluge-web@.service
  systemctl enable deluged@${username}
  systemctl enable deluge-web@${username}
  systemctl start deluged@${username}
  systemctl start deluge-web@${username}

}

function _installDeluge5() {
  echo "Deluge Install Complete!" >>"${OUTTO}" 2>&1;
  sleep 5
  echo >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
}
function _installDeluge6() {
  exit
}



echo "Installing deluge ... " >>"${OUTTO}" 2>&1;_installDeluge1
echo "Setting up deluge configurations ... " >>"${OUTTO}" 2>&1;_installDeluge2
echo "Setting up deluge permissions ... " >>"${OUTTO}" 2>&1;_installDeluge3
echo "Setting up services and starting deluge ... " >>"${OUTTO}" 2>&1;_installDeluge4
_installDeluge5
_installDeluge6
