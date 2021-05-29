#!/bin/bash
MASTER=$(_get_master_username)
systemctl stop -q syncthing@"${MASTER}"
apt_remove --purge syncthing
rm /etc/systemd/system/syncthing@.service
rm -f /etc/nginx/apps/syncthing.conf
systemctl reload nginx
rm /install/.syncthing.lock
