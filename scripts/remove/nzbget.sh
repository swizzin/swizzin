#!/bin/bash

users=($(cat /etc/htpasswd | cut -d ":" -f 1))

for u in "${users[@]}"; do
  systemctl stop nzbget@$u
  systemctl disable nzbget@$u
  rm -rf /home/$u/nzbget
  rm /etc/nginx/conf.d/$u.nzbget.conf
done

rm /etc/systemd/system/nzbget@.service
rm /etc/nginx/apps/nzbget.conf
rm /install/.nzbget.lock