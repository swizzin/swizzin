#!/bin/bash
MASTER=$(cut -d: -f1 < /root/.master.info)
systemctl stop syncthing@${MASTER}
apt_remove --purge syncthing
rm /etc/systemd/system/syncthing@.service
rm -f  /etc/nginx/apps/syncthing.conf
systemctl reload nginx
rm /install/.syncthing.lock
