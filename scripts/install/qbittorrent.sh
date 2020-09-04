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

if [[ -n $1 ]]; then
    user=$1
    qbittorrent_user_config ${user}
    if [[ -f /install/.nginx.sh ]]; then
        bash /etc/swizzin/scripts/nginx/qbittorrent.sh
        systemctl reload nginx
    fi
    exit 0
fi

whiptail_qbittorrent
if ! skip_libtorrent_rasterbar; then
    whiptail_libtorrent_rasterbar
    echo "Building libtorrent-rasterbar"; build_libtorrent_rasterbar
fi

echo "Building qBittorrent"; build_qbittorrent
qbittorrent_service
for user in ${users[@]}; do
    qbittorrent_user_config ${user}
    systemctl enable --now qbittorrent@${user}
done
if [[ -f /install/.nginx.lock ]]; then
    bash /etc/swizzin/scripts/nginx/qbittorrent.sh
    systemctl reload nginx
fi

touch /install/.qbittorrent.lock