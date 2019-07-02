#!/bin/bash
user=$(cat /root/.master.info | cut -d: -f1)
systemctl disable --now bazarr

rm -rf /home/$user/bazarr
rm -rf /etc/nginx/apps/bazarr.conf
rm -rf /install/.bazarr.lock
rm -rf /etc/systemd/system/bazarr.service
systemctl reload nginx