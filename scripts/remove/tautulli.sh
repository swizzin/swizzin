#!/bin/bash
systemctl stop tautulli
systemctl disable tautulli
rm -rf /opt/tautulli
rm /install/.tautulli.lock
rm -f /etc/nginx/apps/tautulli.conf
systemctl reload nginx
rm /etc/systemd/system/tautulli.service
