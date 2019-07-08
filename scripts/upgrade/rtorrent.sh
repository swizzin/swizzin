#!/bin/bash
# rtorrent upgrade/downgrade/reinstall script
# Author: liara

if [[ ! -f /install/.rtorrent.lock ]]; then
  echo "rTorrent doesn't appear to be installed. What do you hope to accomplish by running this script?"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  export log="/dev/null"
fi
. /etc/swizzin/sources/functions/rtorrent
whiptail_rtorrent

user=$(cat /root/.master.info | cut -d: -f1)
rutorrent="/srv/rutorrent/"
users=($(cat /etc/htpasswd | cut -d ":" -f 1))

for u in "${users[@]}"; do
  systemctl stop rtorrent@${u}
done

if [[ -n $noexec ]]; then
	mount -o remount,exec /tmp
	noexec=1
fi
isdeb=$(dpkg -l | grep rtorrent)
if [[ -z $isdeb ]]; then
	echo "Removing old rTorrent binaries and libraries ... ";remove_rtorrent_legacy
fi
echo "Checking rTorrent Dependencies ... ";depends_rtorrent
echo "Building xmlrpc-c from source ... ";build_xmlrpc-c
echo "Building libtorrent from source ... ";build_libtorrent_rakshasa
echo "Building rtorrent from source ... ";build_rtorrent
if [[ -n $noexec ]]; then
	mount -o remount,noexec /tmp
fi

for u in "${users[@]}"; do
	if grep -q localhost /home/$u/.rtorrent.rc; then sed -i 's/localhost/127.0.0.1/g' /home/$u/.rtorrent.rc; fi
  systemctl start rtorrent@${u}
done