#!/bin/bash
# qBittorrent Installer for swizzin
# Author: liara


if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  export log="/root/logs/swizzin.log"
fi
# Source the required functions
. /etc/swizzin/sources/functions/qbittorrent
. /etc/swizzin/sources/functions/libtorrent
. /etc/swizzin/sources/functions/utils
. /etc/swizzin/sources/functions/fpm
users=($(_get_user_list))

whiptail_qbittorrent
if ! skip_libtorrent_rasterbar; then
    whiptail_libtorrent_rasterbar
    echo "Building libtorrent-rasterbar"; build_libtorrent_rasterbar
fi

echo "Building qBittorrent"; build_qbittorrent
for user in ${users[@]}; do
    systemctl try-restart qbittorrent@${user}
done