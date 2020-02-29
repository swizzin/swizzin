#!/bin/bash

if [[ -f /install/.bazarr.lock ]]; then
  if ! grep -q python3 /etc/systemd/system/bazarr.service; then
    echo "Updating bazarr to python3"
    user=$(cut -d: -f1 </root/.master.info)
    if ! command -v python3; then
      apt-get -y -q install python3-dev > /dev/null 2>&1
    fi
    if ! command -v pip3; then
      apt-get -y -q install python3-pip > /dev/null 2>&1
    fi
    cd /home/${user}/bazarr
    sudo -u ${user} bash -c "pip3 install --user -r requirements.txt" > /dev/null 2>&1
    sed -i 's/python /python3 /g' /etc/systemd/system/bazarr.service
    systemctl daemon-reload
    systemctl try-restart bazarr
  fi