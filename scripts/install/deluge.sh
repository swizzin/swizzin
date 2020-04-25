#!/bin/bash
#
# [Swizzin :: Install Deluge package]
# Author: liara
#
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

function _dconf {
  for u in "${users[@]}"; do
    if [[ ${u} == ${master} ]]; then
      pass=$(cut -d: -f2 < /root/.master.info)
    else
      pass=$(cut -d: -f2 < /root/${u}.info)
    fi
  n=$RANDOM
  DPORT=$((n%59000+10024))
  DWSALT=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1)
  localpass=$(tr -dc 'a-f0-9' < /dev/urandom | fold -w 40 | head -n 1)
  DWP=$(python ${local_packages}/deluge.Userpass.py ${pass} ${DWSALT})
  DUDID=$(python ${local_packages}/deluge.addHost.py)
  # -- Secondary awk command -- #
  #DPORT=$(awk -v min=59000 -v max=69024 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
  DWPORT=$(shuf -i 10001-11000 -n 1)
  ltconfig
  chmod 755 /home/${u}/.config
  chmod 755 /home/${u}/.config/deluge
  export u
  export DPORT
  export ip
  envsubst < /etc/swizzin/conf/deluge.core.conf > /home/${u}/.config/deluge/core.conf

cat > /home/${u}/.config/deluge/web.conf <<DWC
{
  "file": 1,
  "format": 1
}{
  "port": ${DWPORT},
  "enabled_plugins": [],
  "pwd_sha1": "${DWP}",
  "theme": "gray",
  "show_sidebar": true,
  "sidebar_show_zero": false,
  "pkey": "ssl/daemon.pkey",
  "https": true,
  "sessions": {},
  "base": "/",
  "interface": "0.0.0.0",
  "pwd_salt": "${DWSALT}",
  "show_session_speed": false,
  "first_login": false,
  "cert": "ssl/daemon.cert",
  "session_timeout": 3600,
  "default_daemon": "${DUDID}",
  "sidebar_multiple_filters": true
}
DWC
dvermajor=$(deluged -v | grep deluged | grep -oP '\d+\.\d+\.\d+' | cut -d. -f1)

case $dvermajor in
  1)
  SUFFIX=.1.2
  ;;
esac
cat > /home/${u}/.config/deluge/hostlist.conf${SUFFIX} <<DHL
{
  "file": 1,
  "format": 1
}{
  "hosts": [
    [
      "${DUDID}",
      "127.0.0.1",
      ${DPORT},
      "localclient",
      "${localpass}"
    ]
  ]
}
DHL

  echo "${u}:${pass}:10" > /home/${u}/.config/deluge/auth
  echo "localclient:${localpass}:10" >> /home/${u}/.config/deluge/auth
  chmod 600 /home/${u}/.config/deluge/auth
  chown -R ${u}.${u} /home/${u}/.config/

 	. /etc/swizzin/sources/functions/short
  _make_custom_user_dirs ${u}
  if [[ $custom_dirs_made = false ]]; then 
    mkdir /home/${u}/dwatch
    chown ${u}: /home/${u}/dwatch
    mkdir -p /home/${u}/torrents/deluge
    chown ${u}: /home/${u}/torrents/deluge
  fi
done
}

function _dservice {
  if [[ ! -f /etc/systemd/system/deluged@.service ]]; then
  dvermajor=$(deluged -v | grep deluged | grep -oP '\d+\.\d+\.\d+' | cut -d. -f1)
  if [[ $dvermajor == 2 ]]; then args=" -d"; fi
    cat > /etc/systemd/system/deluged@.service <<DD
[Unit]
Description=Deluge Bittorrent Client Daemon
After=network.target

[Service]
Type=simple
User=%i

ExecStart=/usr/bin/deluged -d
ExecStop=/usr/bin/killall -w -s 9 /usr/bin/deluged
Restart=on-failure
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
DD
  fi
  if [[ ! -f /etc/systemd/system/deluge-web@.service ]]; then
    cat > /etc/systemd/system/deluge-web@.service <<DW
[Unit]
Description=Deluge Bittorrent Client Web Interface
After=network.target

[Service]
Type=simple
User=%i

ExecStart=/usr/bin/deluge-web${args}
ExecStop=/usr/bin/killall -w -s 9 /usr/bin/deluge-web
TimeoutStopSec=300
Restart=on-failure

[Install]
WantedBy=multi-user.target
DW
  fi
for u in "${users[@]}"; do
  systemctl enable deluged@${u} >>"${log}" 2>&1
  systemctl enable deluge-web@${u} >>"${log}" 2>&1
  systemctl start deluged@${u}
  systemctl start deluge-web@${u}
done

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/deluge.sh
  service nginx reload
fi

  touch /install/.deluge.lock
}

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  export log="/root/logs/swizzin.log"
fi
local_packages=/usr/local/bin/swizzin
users=($(cut -d: -f1 < /etc/htpasswd))
master=$(cut -d: -f1 < /root/.master.info)
pass=$(cut -d: -f2 < /root/.master.info)
codename=$(lsb_release -cs)
ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
noexec=$(grep "/tmp" /etc/fstab | grep noexec)
. /etc/swizzin/sources/functions/deluge

if [[ -n $1 ]]; then
  users=($1)
  _dconf
  exit 0
fi

whiptail_deluge
if [[ ! -f /install/.libtorrent.lock ]]; then
  whiptail_libtorrent_rasterbar
fi

if [[ -n $noexec ]]; then
	mount -o remount,exec /tmp
	noexec=1
fi

if [[ ! -f /install/.libtorrent.lock ]]; then
  echo "Building libtorrent-rasterbar"; build_libtorrent_rasterbar
fi

echo "Building Deluge"; build_deluge

if [[ -n $noexec ]]; then
	mount -o remount,noexec /tmp
fi

echo "Configuring Deluge"
_dconf
_dservice
