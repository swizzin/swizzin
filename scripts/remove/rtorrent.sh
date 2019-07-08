#!/bin/bash
users=($(cat /etc/htpasswd | cut -d ":" -f 1))

read -n 1 -s -r -p "This will remove rTorrent and all associated interfaces (ruTorrent/Flood). Press any key to continue."
printf "\n"

for u in ${users}; do
  systemctl disable rtorrent@${u}
  systemctl stop rtorrent@{u}
  rm -f /home/${u}/.rtorrent.rc
done

. /etc/swizzin/sources/functions/rtorrent
isdeb=$(dpkg -l | grep rtorrent)
if [[ -z $isdeb ]]; then
	echo "Removing old rTorrent binaries and libraries ... ";remove_rtorrent_legacy
fi

if [[ -n $isdeb ]]; then
  apt-get -y -q purge libtorrent-rakshasa > /dev/null 2>&1
  apt-get -y -q purge rtorrent > /dev/null 2>&1
fi

#apt-get -y remove mktorrent mediainfo
for a in rutorrent flood; do
  if [[ -f /install/.$a.lock ]]; then
    /usr/local/bin/swizzin/remove/$a.sh
  fi
done
rm /etc/systemd/system/rtorrent@.service
rm /install/.rtorrent.lock