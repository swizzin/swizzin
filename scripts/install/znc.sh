#!/bin/bash
#
# ZNC Installer
#
# Originally written for QuickBox.io by liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

DISTRO=$(lsb_release -is)
CODENAME=$(lsb_release -cs)
if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi

echo "Installing ZNC. Please wait ... " >> ${OUTTO} 2>&1
echo "" >> ${OUTTO} 2>&1
echo "" >> ${OUTTO} 2>&1
useradd znc -m -s /bin/bash
passwd znc -l

if [[ $DISTRO == Debian ]]; then
  echo "deb http://packages.temporal-intelligence.net/znc/debian/ ${CODENAME} main" > /etc/apt/sources.list.d/znc.list
  echo "#deb-src http://packages.temporal-intelligence.net/znc/debian/ ${CODENAME} main" >> /etc/apt/sources.list.d/znc.list
  wget --quiet http://packages.temporal-intelligence.net/repo.gpg.key -O - | apt-key add - > /dev/null 2>&1
elif [[ $DISTRO == Ubuntu ]]; then
  sudo apt-get install -q -y python-software-properties software-properties-common > /dev/null 2>&1
  sudo add-apt-repository -q -y ppa:teward/znc > /dev/null 2>&1
fi
  apt-get update -q -y > /dev/null 2>&1
  apt-get install znc -q -y > /dev/null 2>&1
  touch /install/.znc.lock
  sudo -u znc crontab -l | echo -e "*/10 * * * * /usr/bin/znc >/dev/null 2>&1\n@reboot /usr/bin/znc >/dev/null 2>&1" | crontab -u znc - > /dev/null 2>&1
  echo "#### ZNC configuration will now run. Please answer the following prompts ####"
  sleep 5
  sudo -u znc znc --makeconf
  echo "$(cat /home/znc/.znc/configs/znc.conf | grep Port | sed -e 's/^[ \t]*//')" > /srv/panel/db/znc.txt
  echo "$(cat /home/znc/.znc/configs/znc.conf | grep SSL |  sed -e 's/^[ \t]*//')" >> /srv/panel/db/znc.txt

echo "#### ZNC now installed! ####"
