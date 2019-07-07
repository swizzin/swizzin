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
      pass=$(cat /root/.master.info | cut -d: -f2)
    else
      pass=$(cat /root/${u}.info | cut -d: -f2)
    fi
  n=$RANDOM
  DPORT=$((n%59000+10024))
  DWSALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
  DWP=$(python ${local_packages}/deluge.Userpass.py ${pass} ${DWSALT})
  DUDID=$(python ${local_packages}/deluge.addHost.py)
  # -- Secondary awk command -- #
  #DPORT=$(awk -v min=59000 -v max=69024 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
  DWPORT=$(shuf -i 10001-11000 -n 1)
  mkdir -p /etc/skel/.config/deluge/plugins
  if [[ ! -f /etc/skel/.config/deluge/plugins/ltConfig-0.3.1-py2.7.egg ]]; then
    cd /etc/skel/.config/deluge/plugins/
    wget -q https://github.com/ratanakvlun/deluge-ltconfig/releases/download/v0.3.1/ltConfig-0.3.1-py2.7.egg
  fi
  mkdir -p /home/${u}/.config/deluge/plugins
  if [[ ! -f /home/${u}/.config/deluge/plugins/ltConfig-0.3.1-py2.7.egg ]]; then
    cd /home/${u}/.config/deluge/plugins/
    wget -q https://github.com/ratanakvlun/deluge-ltconfig/releases/download/v0.3.1/ltConfig-0.3.1-py2.7.egg
  fi
  chmod 755 /home/${u}/.config
  chmod 755 /home/${u}/.config/deluge
  cat > /home/${u}/.config/deluge/core.conf <<DC
  {
    "file": 1,
    "format": 1
  }{
    "info_sent": 0.0,
    "lsd": true,
    "max_download_speed": -1.0,
    "send_info": false,
    "natpmp": true,
    "move_completed_path": "/home/${u}/Downloads",
    "peer_tos": "0x08",
    "enc_in_policy": 1,
    "queue_new_to_top": false,
    "ignore_limits_on_local_network": true,
    "rate_limit_ip_overhead": true,
    "daemon_port": ${DPORT},
    "torrentfiles_location": "/home/${u}/dwatch",
    "max_active_limit": -1,
    "geoip_db_location": "/usr/share/GeoIP/GeoIP.dat",
    "upnp": false,
    "utpex": true,
    "max_active_downloading": 3,
    "max_active_seeding": -1,
    "allow_remote": true,
    "outgoing_ports": [
      0,
      0
    ],
    "enabled_plugins": [
      "ltConfig"
    ],
    "max_half_open_connections": 50,
    "download_location": "/home/${u}/torrents/deluge",
    "compact_allocation": true,
    "max_upload_speed": -1.0,
    "plugins_location": "/home/${u}/.config/deluge/plugins",
    "max_connections_global": -1,
    "enc_prefer_rc4": true,
    "cache_expiry": 60,
    "dht": true,
    "stop_seed_at_ratio": false,
    "stop_seed_ratio": 2.0,
    "max_download_speed_per_torrent": -1,
    "prioritize_first_last_pieces": true,
    "max_upload_speed_per_torrent": -1,
    "auto_managed": true,
    "enc_level": 2,
    "copy_torrent_file": false,
    "max_connections_per_second": 50,
    "listen_ports": [
      6881,
      6891
    ],
    "max_connections_per_torrent": -1,
    "del_copy_torrent_file": false,
    "move_completed": false,
    "autoadd_enable": false,
    "proxies": {
      "peer": {
        "username": "",
        "password": "",
        "hostname": "",
        "type": 0,
        "port": 8080
      },
      "web_seed": {
        "username": "",
        "password": "",
        "hostname": "",
        "type": 0,
        "port": 8080
      },
      "tracker": {
        "username": "",
        "password": "",
        "hostname": "",
        "type": 0,
        "port": 8080
      },
      "dht": {
        "username": "",
        "password": "",
        "hostname": "",
        "type": 0,
        "port": 8080
      }
    },
    "dont_count_slow_torrents": true,
    "add_paused": false,
    "random_outgoing_ports": true,
    "max_upload_slots_per_torrent": -1,
    "new_release_check": false,
    "enc_out_policy": 1,
    "seed_time_ratio_limit": 7.0,
    "remove_seed_at_ratio": false,
    "autoadd_location": "/home/${u}/dwatch/",
    "max_upload_slots_global": -1,
    "seed_time_limit": 180,
    "cache_size": 512,
    "share_ratio_limit": 2.0,
    "random_port": true,
    "listen_interface": "${ip}"
  }
DC
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
cat > /home/${u}/.config/deluge/hostlist.conf.1.2 <<DHL
{
  "file": 1,
  "format": 1
}{
  "hosts": [
    [
      "${DUDID}",
      "127.0.0.1",
      ${DPORT},
      "${u}",
      "${pass}"
    ]
  ]
}
DHL

  echo "${u}:${pass}:10" > /home/${u}/.config/deluge/auth
  chmod 600 /home/${u}/.config/deluge/auth
  chown -R ${u}.${u} /home/${u}/.config/
  mkdir /home/${u}/dwatch
  chown ${u}: /home/${u}/dwatch
  mkdir -p /home/${u}/torrents/deluge
  chown ${u}: /home/${u}/torrents/deluge
done
}
function _dservice {
  if [[ ! -f /etc/systemd/system/deluged@.service ]]; then
    cat > /etc/systemd/system/deluged@.service <<DD
[Unit]
Description=Deluge Bittorrent Client Daemon
After=network.target

[Service]
Type=simple
User=%I

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
User=%I

ExecStart=/usr/bin/deluge-web
ExecStop=/usr/bin/killall -w -s 9 /usr/bin/deluge-web
TimeoutStopSec=300
Restart=on-failure

[Install]
WantedBy=multi-user.target
DW
  fi
for u in "${users[@]}"; do
  systemctl enable deluged@${u} >>"${OUTTO}" 2>&1
  systemctl enable deluge-web@${u} >>"${OUTTO}" 2>&1
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
  export OUTTO="/root/logs/install.log"
else
  export OUTTO="/dev/null"
fi
local_packages=/usr/local/bin/swizzin
users=($(cat /etc/htpasswd | cut -d ":" -f 1))
master=$(cat /root/.master.info | cut -d: -f1)
pass=$(cat /root/.master.info | cut -d: -f2)
codename=$(lsb_release -cs)
ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
noexec=$(cat /etc/fstab | grep "/tmp" | grep noexec)

if [[ -n $1 ]]; then
  users=($1)
  _dconf
  exit 0
fi

. /etc/swizzin/sources/functions/deluge
whiptail_deluge

if [[ -n $noexec ]]; then
	mount -o remount,exec /tmp
	noexec=1
fi

if [[ ! -f /install/libtorrent.lock ]]; then
  echo "Building libtorrent-rasterbar"; build_libtorrent_rasterbar
fi

echo "Building Deluge"; build_deluge

if [[ -n $noexec ]]; then
	mount -o remount,noexec /tmp
fi

echo "Configuring Deluge"
_dconf
_dservice
