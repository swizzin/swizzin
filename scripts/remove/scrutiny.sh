#!/bin/bash
# Scrutiny installer by flying_sausages for Swizzin 2020
# GPLv3 applies

systemctl disable -q --now scrutiny-web
systemctl disable -q --now scrutiny-collector.timer
systemctl disable -q --now scrutiny-collector.service
rm /etc/systemd/system/scrutiny-*
systemctl daemon-reload

if [[ -f /install/.nginx.lock ]]; then
    rm "/etc/nginx/apps/scrutiny.conf"
    systemctl reload nginx >> "$log" 2>&1
fi

userdel -rf scrutiny
if ask "Remove InfluxDB as well?"; then
    apt_remove influxdb2
    rm /etc/apt/sources.list.d/influxdata.list
fi
rm /install/.scrutiny.lock
