#!/bin/bash
users=($(cut -d: -f1 < /etc/htpasswd))
export log=/dev/null
read -n 1 -s -r -p "This will remove rTorrent and all associated interfaces (ruTorrent/Flood). Press any key to continue."
printf "\n"

for u in ${users}; do
  systemctl disable rtorrent@${u}
  systemctl stop rtorrent@${u}
  rm -f /home/${u}/.rtorrent.rc
done

. /etc/swizzin/sources/functions/rtorrent
isdeb=$(dpkg -l | grep rtorrent)
echo "Removing old rTorrent binaries and libraries ... ";
if [[ -z $isdeb ]]; then
	remove_rtorrent_legacy
else
  remove_rtorrent
fi

for a in rutorrent flood; do
  if [[ -f /install/.$a.lock ]]; then
    /usr/local/bin/swizzin/remove/$a.sh
  fi
done
rm /etc/systemd/system/rtorrent@.service
rm /install/.rtorrent.lock