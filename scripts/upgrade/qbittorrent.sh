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
for user in "${users[@]}"; do
    #Reset user password to ensure login continues to work if doing a major upgrade (>4.1 to <4.2)
    #chpasswd function restarts qbittorrent, which we need to anyway. No need for a further restart.
    password=$(_get_user_password)
    qbittorrent_chpasswd "${user}" "${password}"
done