#!/bin/bash
#
# [Quick Box :: Remove Config Server Firewall package]
#
# QUICKLAB REPOS
# QuickLab _ packages  :   https://github.com/QuickBox/quickbox_packages
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

function _removepyLoad() {
  systemctl stop pyload@${MASTER}.service >/dev/null 2>&1
  systemctl disable pyload@${MASTER}.service >/dev/null 2>&1

  rm /etc/systemd/system/pyload@.service

  rm -rf /home/${MASTER}/.pip
  rm -rf /home/${MASTER}/.pyload
  rm -rf /var/run/pyload
  rm -rf /etc/nginx/apps/pyload.conf
  apt-get -y remove tesseract-ocr \
                    gocr \
                    rhino \
                    pyqt4-dev-tools \
                    python-imaging
  apt-get -y autoremove >/dev/null 2>&1
  apt-get -y autoclean >/dev/null 2>&1
  rm /install/.pyload.lock
}


MASTER=$(cut -d: -f1 < /root/.master.info)


_removepyLoad
