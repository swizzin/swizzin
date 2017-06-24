#!/bin/bash
export distribution=$(lsb_release -is)
export release=$(lsb_release -rs)
export codename=$(lsb_release -cs)
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  log="/srv/panel/db/output.log"
else
  log="/dev/null"
fi

if [ $codename = "jessie" ]; then
    grep "deb http://www.deb-multimedia.org jessie main" /etc/apt/sources.list >> /dev/null || echo "deb http://www.deb-multimedia.org jessie main" >> /etc/apt/sources.list
    apt-get update >> $log 2>&1
    apt-get -y install deb-multimedia-keyring >> $log 2>&1
    apt-get -y install ffmpeg >> $log 2>&1
  else
    apt-get -y install ffmpeg >> $log 2>&1
fi

touch /install/.ffmpeg.lock
