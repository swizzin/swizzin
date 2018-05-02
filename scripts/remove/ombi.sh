#!/bin/bash
systemctl disable ombi
systemctl stop ombi
rm /etc/systemd/system/ombi.service
rm -f /etc/nginx/apps/ombi.conf
service nginx reload

if [[ -d /opt/ombi ]]; then
  rm -rf /opt/ombi
fi

if [[ -d /opt/Ombi ]]; then
  rm -rf /opt/Ombi
fi

rm /install/.ombi.lock
