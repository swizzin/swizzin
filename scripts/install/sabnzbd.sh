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

username=$(cut -d: -f1 < /root/.master.info)
DISTRO=$(lsb_release -is)
RELEASE=$(lsb_release -cs)
PUBLICIP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi

function _rar() {
	cd /tmp
  	wget -q http://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz
  	tar -xzf rarlinux-x64-5.5.0.tar.gz >/dev/null 2>&1
  	cp rar/*rar /bin >/dev/null 2>&1
  	rm -rf rarlinux*.tar.gz >/dev/null 2>&1
  	rm -rf /tmp/rar >/dev/null 2>&1
}

#apt-get -y install software-properties-common >/dev/null 2>&1

#if [[ $DISTRO == "Debian" ]]; then
#  gpg --keyserver http://keyserver.ubuntu.com --recv  F13930B14BB9F05F
#  gpg --export F13930B14BB9F05F > /etc/apt/trusted.gpg.d/jcfp_ubuntu_sab-addons.gpg
#  if [[ $RELEASE = "stretch" ]]; then
#    echo "deb http://ppa.launchpad.net/jcfp/ppa/ubuntu xenial main" > /etc/apt/sources.list.d/sab-addons.list
#  elif [[ $RELEASE = "jessie" ]]; then
#    echo "deb http://ppa.launchpad.net/jcfp/ppa/ubuntu precise main" > /etc/apt/sources.list.d/sab-addons.list
#  fi
#else
#  add-apt-repository -y ppa:jcfp/sab-addons >/dev/null 2>&1
#fi

apt-get update >/dev/null 2>&1
apt-get -y install par2 python-configobj python-dbus python-feedparser python-gi python-libxml2 \
  python-utidylib python-yenc python-cheetah python-openssl screen > /dev/null 2>&1

if [[ -z $(which rar) ]]; then
  if [[ $DISTRO == "Debian" ]]; then
    _rar
  else
    apt-get -y install rar unrar >>/dev/null 2>&1 || { echo "INFO: Could not find rar/unrar in the repositories. It is likely you do not have the multiverse repo enabled. Installing directly."; _rar; }
  fi
fi
cd /home/${username}/
#wget -qO SABnzbd.tar.gz https://github.com/sabnzbd/sabnzbd/releases/download/1.1.1/SABnzbd-1.1.1-src.tar.gz
#tar xf SABnzbd.tar.gz >/dev/null 2>&1
#mv SABnzbd-* SABnzbd
git clone -b 2.3.x https://github.com/sabnzbd/sabnzbd.git /home/${username}/SABnzbd >/dev/null 2>&1
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
ExecStop=/usr/bin/screen -X -S sabnzbd quit
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
