#! /bin/bash
# Medusa installer for swizzin
# Author: liara

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi
distribution=$(lsb_release -is)
codename=$(lsb_release -cs)
user=$(cut -d: -f1 < /root/.master.info)

if [[ $(systemctl is-active sickgear) == "active" ]]; then
  active=sickgear
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

if [[ ! $codename == "jessie" ]]; then
  apt-get -y -q install git-core openssl libssl-dev python3 python3-venv >> $log 2>&1
  python3 -m venv /home/${user}/.venv/medusa
else
  apt-get -y -q install git-core openssl libssl-dev >> $log 2>&1
  . /etc/swizzin/sources/functions/pyenv
  pyenv_install
  pyenv_install_version 3.7.7
  pyenv_create_venv 3.7.7 /home/${user}/.venv/medusa
fi

chown -R ${user}: /home/${user}/.venv/medusa

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

cd /home/${user}/
git clone https://github.com/pymedusa/Medusa.git medusa
chown -R ${user}:${user} medusa

cat > /etc/systemd/system/medusa.service <<MSD
[Unit]
Description=Medusa
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=${user}
Group=${user}
ExecStart=/home/${user}/.venv/medusa/bin/python3 /home/${user}/medusa/SickBeard.py -q --daemon --nolaunch --datadir=/home/${user}/medusa
ExecStop=-/bin/kill -HUP


[Install]
WantedBy=multi-user.target
MSD

systemctl enable --now medusa >>$log 2>&1


if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/medusa.sh
  systemctl reload nginx
fi

touch /install/.medusa.lock
