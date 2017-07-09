#!/bin/bash
systemctl stop plexpy
systemctl disable plexpy
rm -rf /opt/plexpy
rm /install/.plexpy.lock
rm -f /etc/nginx/apps/plexpy.conf
service nginx reload
rm /etc/systemd/system/plexpy.service
