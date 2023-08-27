#!/bin/bash
systemctl stop -q tautulli
systemctl disable -q tautulli
rm -rf /opt/tautulli
rm -rf /opt/.venv/tautulli
rm /install/.tautulli.lock
rm -f /etc/nginx/apps/tautulli.conf
systemctl reload nginx
rm /etc/systemd/system/tautulli.service
