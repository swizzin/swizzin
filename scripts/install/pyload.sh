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
  apt-get install -y tesseract-ocr gocr rhino pyqt4-dev-tools python-imaging >/dev/null 2>&1
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
ExecStart=/usr/bin/python /home/${MASTER}/.pyload/pyLoadCore.py --config=/home/${MASTER}/.pyload --pidfile=/var/run/pyload/pid --daemon
PIDFile=/var/run/pyload/pid
ExecStop=-/bin/kill -HUP
WorkingDirectory=/home/%I/

[Install]
WantedBy=multi-user.target

PYSV

cat >/etc/apache2/sites-enabled/pyload.conf<<PYAP
<Location /pyload>
    ProxyPass http://localhost:8000/pyload
    ProxyPassReverse http://localhost:8000/pyload
    ProxyPreserveHost On
    ProxyHTMLEnable On
    ProxyHTMLCharsetOut *
    ProxyHTMLURLMap / /pyload/
    SetOutputFilter INFLATE;DEFLATE
    AddOutputFilterByType INFLATE;SUBSTITUTE;DEFLATE text/css
    AddOutputFilterByType INFLATE;SUBSTITUTE;DEFLATE text/javascript
    Substitute "s|/media|/pyload/media|i"
    Substitute "s|/json|/pyload/json|i"
    Substitute "s|/api|/pyload/api|i"
    Header edit Location ^https://$ip/(?!pyload\/)(.*)$ https://$ip/pyload/$
</Location>

PYAP

a2enmod proxy_http
a2enmod proxy_html
a2enmod substitute
a2enmod headers

}

function _installpyLoad6() {
  echo "Adjusting permissions ... "
  chown -R ${MASTER}.${MASTER} /home/${MASTER}/.pip
  chown -R ${MASTER}.${MASTER} /home/${MASTER}/.pyload
  chown -R ${MASTER}.${MASTER} /var/run/pyload
}

function _installpyLoad7() {
  echo "Enabling and starting pyLoad services ... "
  touch /install/.pyload.lock
  systemctl daemon-reload >/dev/null 2>&1
  systemctl enable pyload@${MASTER}.service >/dev/null 2>&1
  systemctl start pyload@${MASTER}.service >/dev/null 2>&1
  service apache2 reload
}

function _installpyLoad8() {
  echo "pyLoad Install Complete!"
  echo "Please type: 'setup-pyLoad' in ssh to complete your pyload installation"
  echo "pyLoad Install Complete!" >>"${OUTTO}" 2>&1;
  echo "Please type: 'setup-pyLoad' in ssh to complete your pyload installation" >>"${OUTTO}" 2>&1;
  sleep 2
  echo >>"${OUTTO}" 2>&1;
  echo >>"${OUTTO}" 2>&1;
  echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
}

function _installpyLoad9() {
  exit
}


ip=$(curl -s http://whatismyip.akamai.com)
MASTER=$(cat /srv/rutorrent/home/db/master.txt)
OUTTO=/srv/rutorrent/home/db/output.log


echo "Installing any additional dependencies needed for pyLoad ... " >>"${OUTTO}" 2>&1;_installpyLoad1
echo "Setting up python package management system in /home/${MASTER}/.pip ... " >>"${OUTTO}" 2>&1;_installpyLoad2
echo "Installing pyLoad packages ... " >>"${OUTTO}" 2>&1;_installpyLoad3
echo "Grabbing latest stable pyLoad repository ... " >>"${OUTTO}" 2>&1;_installpyLoad4
echo "Building pyLoad systemd template ... " >>"${OUTTO}" 2>&1;_installpyLoad5
echo "Adjusting permissions ... " >>"${OUTTO}" 2>&1;_installpyLoad6
echo "Enabling and starting pyLoad services ... " >>"${OUTTO}" 2>&1;_installpyLoad7
_installpyLoad8
_installpyLoad9
