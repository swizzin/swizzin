#!/bin/bash
. /etc/swizzin/sources/functions/utils

users=($(_get_user_list))
for user in ${users[@]}; do
    systemctl disable --now qbittorrent@${user}
    rm -rf /home/${user}/.config/qbittorrent
done
rm /etc/nginx/apps/qbittorrent.conf
rm /etc/nginx/conf.d/*.qbittorrent.conf
rm /etc/systemd/system/qbittorrent@.service
dpkg -i qbittorrent-nox

systemctl reload nginx
rm /install/.qbittorrent.lock
