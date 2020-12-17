#!/bin/bash

systemctl disable --now -q panel
rm -rf /srv/panel > /dev/null 2>&1
rm -rf /opt/swizzin
rm -rf /opt/.venv/swizzin
rm -f /etc/nginx/apps/panel.conf
rm -f /etc/sudoers.d/panel
rm /etc/cron.d/set_interface > /dev/null 2>&1
rm /install/.panel.lock
