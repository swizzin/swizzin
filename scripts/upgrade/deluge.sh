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
. /etc/swizzin/sources/functions/libtorrent

whiptail_deluge
dver=$(deluged -v | grep deluged | grep -oP '\d+\.\d+\.\d+')
if [[ $dver == 1.3* ]] && [[ $deluge == master ]]; then
  echo "Major version upgrade detected. User-data will be backed-up."
fi
users=($(cut -d: -f1 < /etc/htpasswd))

for u in "${users[@]}"; do
  if [[ $dver == 1.3* ]] && [[ $deluge == master ]]; then
    echo "'/home/${u}/.config/deluge' -> '/home/$u/.config/deluge.$$'"
    cp -a /home/${u}/.config/deluge /home/${u}/.config/deluge.$$
  fi
done

echo "Checking for outdated deluge install method."; remove_ltcheckinstall

if ! skip_libtorrent_rasterbar; then
    whiptail_libtorrent_rasterbar
    echo "Rebuilding libtorrent ... "; build_libtorrent_rasterbar
fi
cleanup_deluge
echo "Upgrading Deluge. Please wait ... "; build_deluge

if [[ -f /install/.nginx.lock ]]; then
  echo "Reconfiguring deluge nginx configs"
  bash /usr/local/bin/swizzin/nginx/deluge.sh
  systemctl reload nginx
fi

echo "Fixing Web Service and Hostlist ... "; dweb_check

for u in "${users[@]}"; do
  echo "Running ltconfig check ..."; ltconfig
  systemctl try-restart deluged@${u}
  systemctl try-restart deluge-web@${u}
done
