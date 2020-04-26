#!/bin/bash
# Sick Gear Installer for swizzin
# Author: liara

user=$(cut -d: -f1 < /root/.master.info)
codename=$(lsb_release -cs)

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
  echo "Don't worry, your install will remain at /home/${user}/$active"
  while true; do
  read -p "Do you want to disable $active? " yn
      case "$yn" in
          [Yy]|[Yy][Ee][Ss]) disable=yes; break;;
          [Nn]|[Nn][Oo]) disable=; break;;
          *) echo "Please answer yes or no.";;
      esac
  done
  if [[ $disable == "yes" ]]; then
    systemctl disable ${active}
    systemctl stop ${active}
  else
    exit 1
  fi
fi


mkdir -p /home/${user}/.venv
chown ${user}: /home/${user}/.venv
apt-get -y -q update >> $log 2>&1

if [[ ! $codename == ("jessie"|"xenial"|"stretch"|"bionic") ]]; then
  apt-get -y -q install git-core openssl libssl-dev python3 python3-pip python3-dev python3-venv >> $log 2>&1
  python3 -m venv /home/${user}/.venv/sickgear
else
  apt-get -y -q install git-core openssl libssl-dev >> $log 2>&1
  . /etc/swizzin/sources/functions/pyenv
  pyenv_install
  pyenv_install_version 3.7.7
  pyenv_create_venv 3.7.7 /home/${user}/.venv/sickgear
fi

/home/${user}/.venv/sickgear/bin/pip3 install lxml regex scandir soupsieve cheetah3 >> $log 2>&1

chown -R ${user}: /home/${user}/.venv/sickgear

function _rar () {
  cd /tmp
  wget -q http://www.rarlab.com/rar/rarlinux-x64-5.5.0.tar.gz
  tar -xzf rarlinux-x64-5.5.0.tar.gz >/dev/null 2>&1
  cp rar/*rar /bin >/dev/null 2>&1
  rm -rf rarlinux*.tar.gz >/dev/null 2>&1
  rm -rf /tmp/rar >/dev/null 2>&1
}

if [[ -z $(which rar) ]]; then
  apt-get -y install rar unrar >>$log 2>&1 || { echo "INFO: Could not find rar/unrar in the repositories. It is likely you do not have the multiverse repo enabled. Installing directly."; _rar; }
fi
sudo git clone https://github.com/SickGear/SickGear.git  /home/$user/sickgear >/dev/null 2>&1

chown -R $user:$user /home/$user/sickgear

cat > /etc/systemd/system/sickgear.service <<SRS
[Unit]
Description=SickGear
After=syslog.target network.target

[Service]
User=${user}
Group=${user}
ExecStart=/home/${user}/.venv/sickgear/bin/python /home/${user}/sickgear/sickgear.py -q --nolaunch --datadir=/home/${user}/sickgear


[Install]
WantedBy=multi-user.target
SRS
  systemctl daemon-reload
  systemctl enable --now sickgear@$user > /dev/null 2>&1
  sleep 5
  # Restart because first start doesn't always generate the config.ini
  systemctl restart sickgear@$user
  # Sleep to allow time for background processes
  sleep 5

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/sickgear.sh
  systemctl reload nginx
fi

touch /install/.sickgear.lock
