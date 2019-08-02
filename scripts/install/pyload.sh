#!/bin/bash
#
# [Quick Box :: Install pyLoad package]
#
# QUICKLAB REPOS
# QuickLab _ packages  :   https://github.com/QuickBox/QB/packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
# URL                :   https://quickbox.io
#
# Modifications for Swizzin by liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

function _installpyLoad1() {
  echo "Installing any additional dependencies needed for pyLoad ... "
  apt-get install -y tesseract-ocr gocr rhino pyqt4-dev-tools python-imaging python-dev libcurl4-openssl-dev >/dev/null 2>&1
  apt-get -y autoremove >/dev/null 2>&1
}

function _installpyLoad2() {
  echo "Setting up python package management system in /home/${MASTER}/.pip ... "
  mkdir /home/${MASTER}/.pip && cd /home/${MASTER}/.pip
  wget https://bootstrap.pypa.io/get-pip.py >/dev/null 2>&1
  python get-pip.py >/dev/null 2>&1
}

function _installpyLoad3() {
  echo "Installing pyLoad packages ... "
  pip install wheel --upgrade >/dev/null 2>&1
  pip install setuptools --upgrade >/dev/null 2>&1
  pip install ply --upgrade >/dev/null 2>&1
  pip install cryptography --upgrade >/dev/null 2>&1
  pip install distribute >/dev/null 2>&1
  pip install pyOpenSSL >/dev/null 2>&1
  pip install cffi --upgrade >/dev/null 2>&1
  pip install pycurl >/dev/null 2>&1
  pip install django >/dev/null 2>&1
  pip install pyimaging >/dev/null 2>&1
  pip install web2py >/dev/null 2>&1
  pip install beaker >/dev/null 2>&1
  pip install thrift >/dev/null 2>&1
  pip install pycrypto >/dev/null 2>&1
  pip install feedparser >/dev/null 2>&1
  pip install beautifulsoup >/dev/null 2>&1
  pip install tesseract >/dev/null 2>&1
}

function _installpyLoad4() {
  echo "Grabbing latest stable pyLoad repository ... "
  mkdir /home/${MASTER}/.pyload
  cd /home/${MASTER} && git clone --branch "stable" https://github.com/pyload/pyload.git .pyload >/dev/null 2>&1
  printf "/home/${MASTER}/.pyload" > /home/${MASTER}/.pyload/module/config/configdir
  mkdir -p /var/run/pyload
}

function _installpyLoad5() {
  echo "Building pyLoad systemd template ... "
cat >/etc/systemd/system/pyload@.service<<PYSV
[Unit]
Description=pyLoad
After=network.target

[Service]
Type=forking
KillMode=process
User=%I
ExecStart=/usr/bin/python /home/${MASTER}/.pyload/pyLoadCore.py --config=/home/${MASTER}/.pyload --pidfile=/home/${MASTER}/.pyload.pid --daemon
PIDFile=/home/${MASTER}/.pyload.pid
ExecStop=-/bin/kill -HUP
WorkingDirectory=/home/%I/

[Install]
WantedBy=multi-user.target

PYSV
}

function _installpyLoad6() {
  echo "Adjusting permissions ... "
  chown -R ${MASTER}.${MASTER} /home/${MASTER}/.pip
  chown -R ${MASTER}.${MASTER} /home/${MASTER}/.pyload
  chown -R ${MASTER}.${MASTER} /var/run/pyload
}

function _installpyLoad7() {
  touch /install/.pyload.lock
  systemctl daemon-reload >/dev/null 2>&1
  echo "#### pyLoad setup will now run ####"
  if [[ -f /install/.nginx.lock ]]; then
    echo "#### To ensure proper proxy configuration:"
    echo "#### please leave remote access enabled ####"
    echo "#### and do not alter the default port (8000) ####"
  fi
  sleep 5
  /usr/bin/python /home/${MASTER}/.pyload/pyLoadCore.py --setup --config=/home/${MASTER}/.pyload
  chown -R ${MASTER}: /home/${MASTER}/.pyload
  if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/pyload.sh
    service nginx reload
  fi
  echo "Enabling and starting pyLoad services ... "
  systemctl enable pyload@${MASTER}.service >/dev/null 2>&1
  systemctl start pyload@${MASTER}.service >/dev/null 2>&1
  service nginx reload
}

function _installpyLoad8() {
  echo "pyLoad Install Complete!"
  echo "pyLoad Install Complete!" >>"${OUTTO}" 2>&1;
  sleep 2
  echo >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
}

function _installpyLoad9() {
  exit
}


ip=$(curl -s http://whatismyip.akamai.com)
MASTER=$(cut -d: -f1 < /root/.master.info)
if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi


echo "Installing any additional dependencies needed for pyLoad ... " >>"${OUTTO}" 2>&1;_installpyLoad1
echo "Setting up python package management system in /home/${MASTER}/.pip ... " >>"${OUTTO}" 2>&1;_installpyLoad2
echo "Installing pyLoad packages ... " >>"${OUTTO}" 2>&1;_installpyLoad3
echo "Grabbing latest stable pyLoad repository ... " >>"${OUTTO}" 2>&1;_installpyLoad4
echo "Building pyLoad systemd template ... " >>"${OUTTO}" 2>&1;_installpyLoad5
echo "Adjusting permissions ... " >>"${OUTTO}" 2>&1;_installpyLoad6
echo "Enabling and starting pyLoad services ... " >>"${OUTTO}" 2>&1;_installpyLoad7
_installpyLoad8
_installpyLoad9
