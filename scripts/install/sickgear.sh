#!/bin/bash
# Sick Gear Installer for swizzin
# Author: liara

user=$(cut -d: -f1 < /root/.master.info)
codename=$(lsb_release -cs)
. /etc/swizzin/sources/functions/utils

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

if [[ $(systemctl is-active medusa) == "active" ]]; then
  active=medusa
fi

if [[ $(systemctl is-active sickchill) == "active" ]]; then
  active=sickchill
fi

if [[ -n $active ]]; then
  echo "SickChill and Medusa and Sickgear cannot be active at the same time."
  echo "Do you want to disable $active and continue with the installation?"
  echo "Don't worry, your install will remain at /opt/$active"
  while true; do
  read -p "Do you want to disable $active? " yn
      case "$yn" in
          [Yy]|[Yy][Ee][Ss]) disable=yes; break;;
          [Nn]|[Nn][Oo]) disable=; break;;
          *) echo "Please answer yes or no.";;
      esac
  done
  if [[ $disable == "yes" ]]; then
    systemctl disable --now ${active}
  else
    exit 1
  fi
fi


mkdir -p /opt/.venv
chown ${user}: /opt/.venv

if [[ ! $codename =~ ("xenial"|"stretch"|"bionic") ]]; then
  apt_install git-core openssl libssl-dev python3 python3-pip python3-dev python3-venv
  python3 -m venv /opt/.venv/sickgear
else
  apt_install git-core openssl libssl-dev
  #shellcheck source=sources/functions/pyenv
  . /etc/swizzin/sources/functions/pyenv
  pyenv_install
  pyenv_install_version 3.7.7
  pyenv_create_venv 3.7.7 /opt/.venv/sickgear
fi

/opt/.venv/sickgear/bin/pip3 install lxml regex scandir soupsieve cheetah3 >> $log 2>&1

chown -R ${user}: /opt/.venv/sickgear

install_rar

sudo git clone https://github.com/SickGear/SickGear.git  /home/$user/sickgear >> ${log} 2>&1

chown -R $user:$user /home/$user/sickgear

cat > /etc/systemd/system/sickgear.service <<SRS
[Unit]
Description=SickGear
After=syslog.target network.target

[Service]
User=${user}
Group=${user}
ExecStart=/opt/.venv/sickgear/bin/python /opt/sickgear/sickgear.py -q --nolaunch --datadir=/opt/sickgear


[Install]
WantedBy=multi-user.target
SRS
  systemctl daemon-reload
  systemctl enable --now sickgear > /dev/null 2>&1
  sleep 5
  # Restart because first start doesn't always generate the config.ini
  systemctl restart sickgear
  # Sleep to allow time for background processes
  sleep 5

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/sickgear.sh
  systemctl reload nginx
fi

touch /install/.sickgear.lock
