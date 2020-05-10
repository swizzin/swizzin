#!/bin/bash
# SickChill installer for swizzin
# Author: liara

user=$(cut -d: -f1 < /root/.master.info)
codename=$(lsb_release -cs)
. /etc/swizzin/sources/functions/pyenv
. /etc/swizzin/sources/functions/utils


if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

if [[ $(systemctl is-active medusa) == "active" ]]; then
  active=medusa
fi

if [[ $(systemctl is-active sickgear) == "active" ]]; then
  active=sickgear
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

if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
    LIST='git python2.7-dev virtualenv python-virtualenv python-pip'
else
    LIST='git python2.7-dev'
fi

apt-get -y -q update >> $log 2>&1
for depend in $LIST; do
  apt-get -qq -y install $depend >>"${log}" 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depend}. That's probably not good..."; }
done

if [[ ! $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
  python_getpip
fi

python2_venv ${user} sickchill

git clone https://github.com/SickChill/SickChill.git  /opt/sickchill >> ${log} 2>&1
chown -R $user: /opt/sickchill


install_rar

cat > /etc/systemd/system/sickchill.service <<SCSD
[Unit]
Description=SickChill
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=${user}
Group=${user}
ExecStart=/opt/.venv/sickchill/bin/python /opt/sickchill/SickBeard.py -q --daemon --nolaunch --datadir=/opt/sickchill


[Install]
WantedBy=multi-user.target
SCSD

systemctl enable --now sickchill >> ${log} 2>&1

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/sickchill.sh
  systemctl reload nginx
fi

touch /install/.sickchill.lock
