#!/bin/bash
# Deluge upgrade/downgrade/reinstall script
# Author: liara
if [[ ! -f /install/.deluge.lock ]]; then
  echo "Deluge doesn't appear to be installed. What do you hope to accomplish by running this script?"
  exit 1
fi

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  export log="/dev/null"
fi

. /etc/swizzin/sources/functions/deluge
whiptail_deluge
users=($(cat /etc/htpasswd | cut -d ":" -f 1))
noexec=$(cat /etc/fstab | grep "/tmp" | grep noexec)

for u in "${users[@]}"; do
  systemctl stop deluged@${u}
  systemctl stop deluge-web@${u}
done

if [[ -n $noexec ]]; then
  mount -o remount,exec /tmp
  noexec=1
fi

echo "Checking for outdated deluge install method."; remove_ltcheckinstall
echo "Rebuilding libtorrent ... "; build_libtorrent_rasterbar
echo "Upgrading Deluge. Please wait ... "; build_deluge

if [[ -n $noexec ]]; then
	mount -o remount,noexec /tmp
fi

if [[ -f /install/.nginx.lock ]]; then
  echo "Reconfiguring deluge nginx configs"
  bash /usr/local/bin/swizzin/nginx/deluge.sh
  service nginx reload
fi

for u in "${users[@]}"; do
  systemctl start deluged@${u}
  systemctl start deluge-web@${u}
done
