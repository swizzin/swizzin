#!/bin/bash
# Removal script for jellyfin
username="$(cut </root/.master.info -d: -f1)"

systemctl stop "jellyfin.service"
systemctl disable "jellyfin.service"
rm -f "/etc/systemd/system/jellyfin.service"
kill -9 "$(ps xU "${username}" | grep "/home/${username}/.jellyfin/jellyfin -d /home/${username}/.config/Jellyfin$" | awk '{print $1}')" >/dev/null 2>&1
rm -rf "/home/${username}/.jellyfin"
rm -rf "/home/${username}/.config/Jellyfin"
if [[ -f /install/.nginx.lock ]]; then
  rm -f "/etc/nginx/apps/jellyfin.conf"
  service nginx reload
fi
rm -f "/install/.jellyfin.lock"
