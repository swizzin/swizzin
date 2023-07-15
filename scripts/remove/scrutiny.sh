#!/bin/bash
# Scrutiny installer by flying_sausages for Swizzin 2020
# GPLv3 applies

systemctl disable -q --now scrutiny-web
systemctl disable -q --now scrutiny-collector.timer
systemctl disable -q --now scrutiny-collector.service

userdel -rf scrutiny
if ask "Remove InfluxDB as well?"; then
    apt_remove influxdb2
    rm /etc/apt/sources.list.d/influxdata.list
fi
rm /install/.scrutiny.lock
