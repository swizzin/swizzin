#!/bin/bash

if [[ -f /install/.bazarr.lock ]]; then
  codename=$(lsb_release -cs)
  user=$(cut -d: -f1 </root/.master.info)
  if ! grep -q .venv /etc/systemd/system/bazarr.service; then
    echo "Updating bazarr to python3 virtualenv"
    if [[ $codename =~ ("bionic"|"stretch"|"xenial"|"jessie") ]]; then
      . /etc/swizzin/sources/functions/pyenv
      log=/root/logs/swizzin.log
      pyenv_install
      pyenv_install_version 3.7.7
      pyenv_create_venv 3.7.7 /home/${user}/.venv/bazarr
      chown -R ${user}: /home/${user}/.venv/bazarr
    else
      apt-get update -y -q >/dev/null 2>&1
      apt-get -y -q install python3-pip python3-dev python3-venv >/dev/null 2>&1
      mkdir -p /home/${user}/.venv/bazarr
      python3 -m venv /home/${user}/.venv/bazarr
      chown -R ${user}: /home/${user}/.venv/bazarr
    fi
    cd /home/${user}/bazarr
    sudo -u ${user} bash -c "/home/${user}/.venv/bazarr/bin/pip3 install -r requirements.txt" > /dev/null 2>&1
    sed -i "s|ExecStart=.*|ExecStart=/home/${user}/.venv/bazarr/bin/python3 /home/${user}/bazarr/bazarr.py|g" /etc/systemd/system/bazarr.service
    systemctl daemon-reload
    systemctl try-restart bazarr
  fi
fi