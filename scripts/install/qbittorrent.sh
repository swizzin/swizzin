#!/bin/bash
# qBittorrent Installer for swizzin
# Author: liara

# Source the required functions
. /etc/swizzin/sources/functions/qbittorrent
. /etc/swizzin/sources/functions/libtorrent
. /etc/swizzin/sources/functions/utils
. /etc/swizzin/sources/functions/fpm

users=($(_get_user_list))

if [[ -n $1 ]]; then
    user=$1
    qbittorrent_user_config ${user}
    if islocked "nginx"; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/qbittorrent.sh
        systemctl reload nginx
        echo_progress_done
    fi
    exit 0
fi

whiptail_qbittorrent
check_client_compatibility
if ! skip_libtorrent_rasterbar; then
    whiptail_libtorrent_rasterbar
    echo_progress_start "Building libtorrent-rasterbar"
    build_libtorrent_rasterbar
    echo_progress_done "Build completed"
fi

echo_progress_start "Building qBittorrent"
build_qbittorrent
echo_progress_done

qbittorrent_service
for user in ${users[@]}; do
    echo_progress_start "Enabling qbittorrent for $user"
    qbittorrent_user_config ${user}
    systemctl enable -q --now qbittorrent@${user} 2>&1 | tee -a $log
    echo_progress_done "Started qbt for $user"
done
if islocked "nginx"; then
    echo_progress_start "Configuring nginx"
    bash /etc/swizzin/scripts/nginx/qbittorrent.sh
    systemctl reload nginx >> $log 2>&1
    echo_progress_done
fi

lock "qbittorrent"
