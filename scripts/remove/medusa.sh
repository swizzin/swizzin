#!/bin/bash
# Medusa Uninstaller for Swizzin
# Author: liara

systemctl disable --now -q medusa

sudo rm /etc/nginx/apps/medusa.conf > /dev/null 2>&1
sudo rm /etc/systemd/medusa.service > /dev/null 2>&1
systemctl reload nginx
rm -rf /opt/medusa
rm -rf /opt/.venv/medusa
if [ -z "$(ls -A /opt/.venv)" ]; then
   rm -rf  /opt/.venv
fi

sudo rm /install/.medusa.lock


