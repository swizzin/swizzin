#!/bin/bash
MASTER=$(cat /root/.master.info | cut -d: -f1)
systemctl stop syncthing@${MASTER}
apt-get -q -y purge syncthing
rm /etc/systemd/system/syncthing@.service
rm -f  /etc/nginx/apps/syncthing.conf
service nginx reload
rm /install/.syncthing.lock
