#!/bin/bash
systemctl stop tautulli
systemctl disable tautulli
rm -rf /opt/tautulli
rm /install/.tautulli.lock
rm -f /etc/nginx/apps/tautulli.conf
service nginx reload
rm /etc/systemd/system/tautulli.service
