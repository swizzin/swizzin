#!/bin/bash
systemctl stop -q tautulli
systemctl disable -q tautulli
rm -rf /opt/tautulli
unlock "tautulli"
rm -f /etc/nginx/apps/tautulli.conf
systemctl reload nginx
rm /etc/systemd/system/tautulli.service
