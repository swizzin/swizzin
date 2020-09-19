#!/bin/bash
#
# [Swizzin :: Install Emby package]
#
# Author: liara
#
# swizzin Copyright (C) 2019 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi
username=$(cut -d: -f1 < /root/.master.info)

if [[ ! $(command -v mono) ]]; then
  echo "Adding mono repository and installing mono ... "
  . /etc/swizzin/sources/functions/mono
  mono_repo_setup
  apt_install libmono-cil-dev
fi

echo "Installing emby from GitHub releases ... "
  current=$(curl -L -s -H 'Accept: application/json' https://github.com/MediaBrowser/Emby.Releases/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
  cd /tmp
  wget -q -O emby.dpkg https://github.com/MediaBrowser/Emby.Releases/releases/download/${current}/emby-server-deb_${current}_amd64.deb
  dpkg -i emby.dpkg >> $log 2>&1
  rm emby.dpkg

  if [[ -f /etc/emby-server.conf ]]; then
    printf "\nEMBY_USER="${username}"\nEMBY_GROUP="${username}"\n" >> /etc/emby-server.conf
  fi

if [[ -f /install/.nginx.lock ]]; then
echo "Setting up emby nginx configuration ... "
  bash /usr/local/bin/swizzin/nginx/emby.sh
  systemctl reload nginx
fi

usermod -a -G ${username} emby

systemctl restart emby-server >/dev/null 2>&1
touch /install/.emby.lock
  
