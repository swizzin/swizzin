#!/bin/bash
. /etc/swizzin/sources/functions/utils

users=($(_get_user_list))
for user in ${users[@]}; do
    systemctl disable --now -q qbittorrent@${user}
    rm -rf /home/${user}/.config/qbittorrent
done
rm /etc/nginx/apps/qbittorrent.conf
rm /etc/nginx/conf.d/*.qbittorrent.conf
rm /etc/systemd/system/qbittorrent@.service
dpkg -r qbittorrent-nox > /dev/null 2>&1

if dpkg -s qtbase5-swizzin > /dev/null 2>&1; then
    dpkg -r qtbase5-swizzin > /dev/null 2>&1
fi
if dpkg -s qttools5-swizzin > /dev/null 2>&1; then
    dpkg -r qttools5-swizzin > /dev/null 2>&1
fi

systemctl reload nginx
rm /install/.qbittorrent.lock

if [[ ! -f /install/.deluge.lock ]]; then
    bash /etc/swizzin/scripts/remove/libtorrent.sh
fi
