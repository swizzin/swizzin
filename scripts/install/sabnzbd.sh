#!/bin/bash
#
# [Quick Box :: Install sabnzbd]
#
# QUICKLAB REPOS
# QuickLab _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | kclawl
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

username=$(cat /root/.master.info | cut -d: -f1)
DISTRO=$(lsb_release -is)
PUBLICIP=$(ip route get 8.8.8.8 | awk '{printf $7}')
if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi

apt-get -y install software-properties-common >/dev/null 2>&1
add-apt-repository -y ppa:jcfp/sab-addons >/dev/null 2>&1

if [[ $DISTRO == "Debian" ]]; then
  gpg --keyserver http://keyserver.ubuntu.com --recv  F13930B14BB9F05F
  gpg --export F13930B14BB9F05F > /etc/apt/trusted.gpg.d/jcfp_ubuntu_sab-addons.gpg
fi

apt-get update >/dev/null 2>&1
apt-get -y install par2-tbb python-openssl python-pip python-sabyenc python-cheetah screen >/dev/null 2>&1
cd /home/${username}/
#wget -qO SABnzbd.tar.gz https://github.com/sabnzbd/sabnzbd/releases/download/1.1.1/SABnzbd-1.1.1-src.tar.gz
#tar xf SABnzbd.tar.gz >/dev/null 2>&1
#mv SABnzbd-* SABnzbd
git clone -b 2.1.x https://github.com/sabnzbd/sabnzbd.git /home/${username}/SABnzbd >/dev/null 2>&1
chown ${username}.${username} -R SABnzbd
#rm SABnzbd.tar.gz
pip install http://www.golug.it/pub/yenc/yenc-0.4.0.tar.gz >/dev/null 2>&1
apt-get install p7zip-full -y >/dev/null 2>&1
touch /install/.sabnzbd.lock

cat >/etc/systemd/system/sabnzbd@.service<<EOF
[Unit]
Description=sabnzbd
After=network.target

[Service]
Type=forking
KillMode=process
User=%I
ExecStart=/usr/bin/screen -f -a -d -m -S sabnzbd python SABnzbd/SABnzbd.py --browser 0 --server 127.0.0.1:65080 --https 65443
ExecStop=/bin/kill -HUP $MAINPID
WorkingDirectory=/home/%I/

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload >/dev/null 2>&1
systemctl enable sabnzbd@${username}.service >/dev/null 2>&1
systemctl start sabnzbd@${username}.service >/dev/null 2>&1

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/sabnzbd.sh
  service nginx reload
fi
