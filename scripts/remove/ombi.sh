#!/bin/bash
systemctl disable ombi
systemctl stop ombi
rm /etc/systemd/system/ombi.service
rm -f /etc/nginx/apps/ombi.conf
systemctl reload nginx

apt_remove ombi

if [[ -d /opt/ombi ]]; then
  rm -rf /opt/ombi
  rm -rf /etc/ombi
fi

if [[ -d /opt/Ombi ]]; then
  rm -rf /opt/Ombi
  rm -rf /etc/Ombi
fi

rm /install/.ombi.lock
