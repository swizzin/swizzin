#!/bin/bash

if [[ -f /install/.bazarr.lock ]]; then
  codename=$(lsb_release -cs)
  user=$(cut -d: -f1 </root/.master.info)
  if ! grep -q .venv /etc/systemd/system/bazarr.service; then
    echo "Updating bazarr to python3 virtualenv"
    if [[ $codename =~ ("bionic"|"stretch"|"xenial") ]]; then
      . /etc/swizzin/sources/functions/pyenv
      log=/root/logs/swizzin.log
      pyenv_install
      pyenv_install_version 3.7.7
      pyenv_create_venv 3.7.7 /opt/.venv/bazarr
      chown -R ${user}: /opt/.venv/bazarr
    else
      apt_install python3-pip python3-dev python3-venv
      mkdir -p /opt/.venv/bazarr
      python3 -m venv /opt/.venv/bazarr
      chown -R ${user}: /opt/.venv/bazarr
    fi
    mv /home/${user}/bazarr /opt
    sudo -u ${user} bash -c "/opt/.venv/bazarr/bin/pip3 install -r requirements.txt" > /dev/null 2>&1
    sed -i "s|ExecStart=.*|ExecStart=/opt/.venv/bazarr/bin/python3 /opt/bazarr/bazarr.py|g" /etc/systemd/system/bazarr.service
    sed -i "s|WorkingDirectory=.*|WorkingDirectory=/opt/bazarr|g" /etc/systemd/system/bazarr.service
    systemctl daemon-reload
    systemctl try-restart bazarr
  fi

  if ! grep -q numpy <(/opt/.venv/bazarr/bin/pip freeze); then 
    sudo -u ${user} bash -c "/opt/.venv/bazarr/bin/pip3 install -r /opt/bazarr/requirements.txt" > /dev/null 2>&1
    systemctl try-restart bazarr
  fi
fi