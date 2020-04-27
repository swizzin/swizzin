#!/bin/bash
# SickChill installer for swizzin
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

if [[ $(systemctl is-active sickgear) == "active" ]]; then
  active=sickgear
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
    systemctl disable --now ${active}
  else
    exit 1
  fi
fi

if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
    LIST='git python2-dev virtualenv python-pip'
else
    LIST='git python2-dev'
fi

apt-get -y -q update >> $log 2>&1
for depend in $LIST; do
  apt-get -qq -y install $depend >>"${log}" 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depend}. That's probably not good..."; }
done

if [[ ! $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
  . /etc/swizzin/sources/functions/pyenv
  python_getpip
  pip install -m virtualenv >>"${log}" 2>&1
fi

echo "Setting up the SickChill venv ..."
mkdir -p /home/${user}/.venv
chown ${user}: /home/${user}/.venv
python2 -m virtualenv /home/${user}/.venv/sickchill >>"${log}" 2>&1
chown -R ${user}: /home/${user}/.venv/sickchill

git clone https://github.com/SickChill/SickChill.git  /home/$user/sickchill >> ${log} 2>&1
chown -R $user: /home/${user}/sickchill


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

cat > /etc/systemd/system/sickchill.service <<SCSD
[Unit]
Description=SickChill
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=${user}
Group=${user}
ExecStart=/home/${user}/.venv/sickchill/bin/python /home/${user}/sickchill/SickBeard.py -q --daemon --nolaunch --datadir=/home/${user}/sickchill


[Install]
WantedBy=multi-user.target
SCSD

systemctl enable --now sickchill >> ${log} 2>&1

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/sickchill.sh
  systemctl reload nginx
fi

touch /install/.sickchill.lock
