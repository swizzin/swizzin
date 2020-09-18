#!/bin/bash
#
# [Swizzin :: Install AutoDL-IRSSI package]
#
# Originally written for QuickBox
# Ported from QuickBox and modified for Swizzin by liara
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


_string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15 ; }

function _installautodl() {
  APT="irssi screen unzip libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libjson-perl libjson-xs-perl libxml-libxslt-perl"
  apt_install $APT
}

function _autoconf {
    for u in "${users[@]}"; do
      IRSSI_PASS=$(_string)
      IRSSI_PORT=$(shuf -i 20000-61000 -n 1)
      mkdir -p "/home/${u}/.irssi/scripts/autorun/" >>"${OUTTO}" 2>&1
      cd "/home/${u}/.irssi/scripts/"
      curl -sL http://git.io/vlcND | grep -Po '(?<="browser_download_url":).*?[^\\].zip"' | sed 's/"//g' | xargs wget --quiet -O autodl-irssi.zip
      unzip -o autodl-irssi.zip >>"${OUTTO}" 2>&1
      rm autodl-irssi.zip
      cp autodl-irssi.pl autorun/
      mkdir -p "/home/${u}/.autodl" >>"${OUTTO}" 2>&1
      touch "/home/${u}/.autodl/autodl.cfg"
cat >"/home/${u}/.autodl/autodl.cfg"<<ADC
[options]
gui-server-port = ${IRSSI_PORT}
gui-server-password = ${IRSSI_PASS}
ADC
      chown -R $u: /home/${u}/.autodl/
      chown -R $u: /home/${u}/.irssi/
  done
  if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/autodl.sh
  fi
}

function _autoservice {
cat >"/etc/systemd/system/irssi@.service"<<ADC
[Unit]
Description=AutoDL IRSSI
After=network.target

[Service]
Type=forking
KillMode=none
User=%i
ExecStart=/usr/bin/screen -d -m -fa -S irssi /usr/bin/irssi
ExecStop=/usr/bin/screen -S irssi -X stuff '/quit\n'
WorkingDirectory=/home/%i/

[Install]
WantedBy=multi-user.target
ADC

for u in "${users[@]}"; do
  systemctl enable --now irssi@${u} >>"${OUTTO}" 2>&1
done
}

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
else
  OUTTO="/root/logs/swizzin.log"
fi
users=($(cut -d: -f1 < /etc/htpasswd))

if [[ -n $1 ]]; then
  users=($1)
  _autoconf
  exit 0
fi

_installautodl
_autoconf
_autoservice
touch /install/.autodl.lock