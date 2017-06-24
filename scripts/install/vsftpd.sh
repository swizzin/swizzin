#!/bin/bash
# Install script for vsftpd
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  log="/srv/panel/db/output.log"
else
  log="/dev/null"
fi

apt-get -y update >> $log 2>&1
apt-get -y install vsftpd >> $log 2>&1

touch /install/.vsftpd.conf
