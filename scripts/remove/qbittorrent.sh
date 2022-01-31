#!/bin/bash
. /etc/swizzin/sources/functions/utils
. /etc/swizzin/sources/functions/libtorrent

users=($(_get_user_list))
for user in ${users[@]}; do
    systemctl disable --now -q qbittorrent@${user}
    rm -rf /home/${user}/.config/qbittorrent
done
rm -f /etc/systemd/system/qbittorrent@.service
dpkg -r qbittorrent-nox > /dev/null 2>&1
dpkg -r libtorrent-rasterbar > /dev/null 2>&1

if [[ ! -f /install/.deluge.lock ]]; then
    apt_remove --purge ^libtorrent-rasterbar*
    dpkg -r python-libtorrent > /dev/null 2>&1
    dpkg -r python3-libtorrent > /dev/null 2>&1
fi

for swizz_dep in qtbase5-swizzin qttools5-swizzin qt6-swizzin cmake-swizzin; do
    if check_installed ${swizz_dep}; then
        dpkg -r ${swizz_dep} > /dev/null 2>&1
    fi
done

if [[ -f /install/.nginx.lock ]]; then
    systemctl reload nginx
    rm -f /etc/nginx/apps/qbittorrent.conf
    rm -f /etc/nginx/conf.d/*.qbittorrent.conf
fi
rm /install/.qbittorrent.lock
