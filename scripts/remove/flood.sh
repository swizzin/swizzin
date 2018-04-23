#!/bin/bash
# Flood uninstaller
# Author: liara

users=($(cat /etc/htpasswd | cut -d ":" -f 1))
for u in "${users[@]}"; do
  systemctl disable flood@$u
  systemctl stop flood@$u
  rm -rf /home/$u/.flood
  rm -rf /etc/nginx/conf.d/$u.flood.conf
done
rm -rf /etc/nginx/apps/flood.conf
if [[ ! -f /install/.rutorrent.lock ]]; then
  rm -rf /etc/nginx/apps/rindex.conf
  rm -f /etc/nginx/apps/${u}.scgi.conf
fi
rm -rf /etc/systemd/system/flood@.service
systemctl reload nginx
rm -rf /install/.flood.lock

users=($(cat /etc/htpasswd | cut -d ":" -f 1))

rm -rf /srv/rutorrent
rm -rf /etc/nginx/apps/rutorrent.conf
