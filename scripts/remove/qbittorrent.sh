#!/bin/bash
. /etc/swizzin/sources/functions/utils
. /etc/swizzin/sources/functions/libtorrent

check_libtorrent_rasterbar_method

users=($(_get_user_list))
for user in ${users[@]}; do
    systemctl disable --now -q qbittorrent@${user}
    rm -rf /home/${user}/.config/qbittorrent
done
rm /etc/nginx/apps/qbittorrent.conf
rm /etc/nginx/conf.d/*.qbittorrent.conf
rm /etc/systemd/system/qbittorrent@.service
dpkg -r qbittorrent-nox > /dev/null 2>&1
dpkg -r libtorrent-rasterbar > /dev/null 2>&1

if [[ ! -f /install/.deluge.lock ]]; then
    apt_remove --purge ^libtorrent-rasterbar* python-libtorrent python3-libtorrent
fi

if dpkg -s qtbase5-swizzin > /dev/null 2>&1; then
    dpkg -r qtbase5-swizzin > /dev/null 2>&1
fi
if dpkg -s qttools5-swizzin > /dev/null 2>&1; then
    dpkg -r qttools5-swizzin > /dev/null 2>&1
fi

systemctl reload nginx
rm /install/.qbittorrent.lock
