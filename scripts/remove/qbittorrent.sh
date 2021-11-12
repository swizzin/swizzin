#!/bin/bash
. /etc/swizzin/sources/functions/utils
. /etc/swizzin/sources/functions/libtorrent

users=($(_get_user_list))
for user in ${users[@]}; do
    systemctl disable --now -q qbittorrent
    rm -rf/var/lib/Qbittorrent
done
rm -f /etc/systemd/system/qbittorrent.service
dpkg -r qbittorrent-nox > /dev/null 2>&1
dpkg -r libtorrent-rasterbar > /dev/null 2>&1

if [[ ! -f /install/.deluge.lock ]]; then
    apt_remove --purge ^libtorrent-rasterbar*
    dpkg -r python-libtorrent > /dev/null 2>&1
    dpkg -r python3-libtorrent > /dev/null 2>&1
fi

if dpkg -s qtbase5-swizzin > /dev/null 2>&1; then
    dpkg -r qtbase5-swizzin > /dev/null 2>&1
fi
if dpkg -s qttools5-swizzin > /dev/null 2>&1; then
    dpkg -r qttools5-swizzin > /dev/null 2>&1
fi

if [[ -f /install/.nginx.lock ]]; then
    systemctl reload nginx
    rm -f /etc/nginx/apps/qbittorrent.conf
    rm -f /etc/nginx/conf.d/*.qbittorrent.conf
fi
rm /install/.qbittorrent.lock
