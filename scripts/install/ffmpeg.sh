#!/bin/bash
#
# [Swizzin :: Install ffmpeg package]
#
# Author:   liara
#
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

export distribution=$(lsb_release -is)
export release=$(lsb_release -rs)
export codename=$(lsb_release -cs)
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

if [ $codename = "jessie" ]; then
    grep "deb http://www.deb-multimedia.org jessie main" /etc/apt/sources.list >> /dev/null || { echo "deb http://www.deb-multimedia.org jessie main" >> /etc/apt/sources.list; }
    apt-get update >> $log 2>&1
    apt-get -y install deb-multimedia-keyring >> $log 2>&1
    apt-get -y install ffmpeg >> $log 2>&1
  else
    apt-get -y install ffmpeg >> $log 2>&1
fi

touch /install/.ffmpeg.lock
