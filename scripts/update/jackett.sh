#!/bin/bash
# Jackett updater script

if [[ -f /install/.jackett.lock ]]; then
  if grep -q "WorkingDirectory=/home/%I/Jackett" /etc/systemd/system/jackett@.service; then
    :
  else
    sed -i 's/WorkingDirectory.*/WorkingDirectory=\/home\/%I\/Jackett/g' /etc/systemd/system/jackett@.service
    sleep 1; systemctl daemon-reload
  fi

  if grep -q "proxy_set_header Host" /etc/nginx/apps/jackett.conf; then
    sed -i "/proxy_set_header Host/d" /etc/nginx/apps/jackett.conf
    systemctl reload nginx
  fi
fi