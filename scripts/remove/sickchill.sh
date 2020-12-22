#!/bin/bash
#
# Uninstaller for sickchill
#
systemctl disable --now -q sickchill
rm -rf /opt/sickchill
rm -rf /opt/.venv/sickchill
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi
rm /etc/nginx/apps/sickchill.conf > /dev/null 2>&1
rm /etc/systemd/sickchill.service > /dev/null 2>&1
systemctl reload nginx
rm -f /install/.sickchill.lock
