#!/bin/bash
systemctl disable ombi
systemctl stop ombi
rm /etc/systemd/system/ombi.service
rm -f /etc/nginx/apps/ombi.conf
service nginx reload
rm -rf /opt/ombi
rm /install/.ombi.lock
