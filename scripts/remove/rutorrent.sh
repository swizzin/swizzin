#!/bin/bash
# ruTorrent removal
# Author: liara

rm -rf /srv/rutorrent
rm -rf /etc/nginx/apps/rutorrent.conf
if [[ ! -f /install/.flood.lock ]]; then
  rm -rf /etc/nginx/apps/rindex.conf
fi
rm -rf /install/.rutorrent.lock
systemctl reload nginx