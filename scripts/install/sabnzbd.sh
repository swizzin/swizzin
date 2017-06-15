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

_sab() {
  add-apt-repository ppa:jcfp/sab-addons
  apt update
  apt -y install par2-tbb python-openssl python-sabyenc python-cheetah >/dev/null 2>&1
  cd /home/${username}/
  #wget -qO SABnzbd.tar.gz https://github.com/sabnzbd/sabnzbd/releases/download/1.1.1/SABnzbd-1.1.1-src.tar.gz
  #tar xf SABnzbd.tar.gz >/dev/null 2>&1
  #mv SABnzbd-* SABnzbd
  git clone https://github.com/sabnzbd/sabnzbd.git /home/${username}/SABnzbd
  chown ${username}.${username} -R SABnzbd
  rm SABnzbd.tar.gz
  pip install http://www.golug.it/pub/yenc/yenc-0.4.0.tar.gz
  apt install p7zip-full -y
  touch /install/.sabnzbd.lock
}

_upstart() {
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

cat > /etc/apache2/sites-enabled/sabnzbd.conf <<EOF
<Location /sabnzbd>
ProxyPass http://localhost:65080/sabnzbd
ProxyPassReverse http://localhost:65080/sabnzbd
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${username}
</Location>
EOF
chown www-data: /etc/apache2/sites-enabled/sabnzbd.conf
service apache2 reload

}

_sabnzbdenable() {
  systemctl daemon-reload >/dev/null 2>&1
  systemctl enable sabnzbd@${username}.service >/dev/null 2>&1
  systemctl start sabnzbd@${username}.service >/dev/null 2>&1
}

_sabnzbdcomplete() {
  echo "SABnzbd Install Complete!" >>"${OUTTO}" 2>&1;
  sleep 5
  echo >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
}

_sabnzbdexit() {
  exit
}

username=$(cat /srv/rutorrent/home/db/master.txt)
PUBLICIP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')
OUTTO=/srv/rutorrent/home/db/output.log

echo "Installing sabnzbd ... " >>"${OUTTO}" 2>&1;_sab
echo "Creating sabnzbd systemd template ... " >>"${OUTTO}" 2>&1;_upstart
echo "Enabling sabnzbd services ... " >>"${OUTTO}" 2>&1;_sabnzbdenable
_sabnzbdcomplete
_sabnzbdexit
