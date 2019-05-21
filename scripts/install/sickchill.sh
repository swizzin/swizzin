#!/bin/bash
# SickChill installer for swizzin
# Author: liara

user=$(cat /root/.master.info | cut -d: -f1)
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/dev/null"
fi

if [[ $(systemctl is-active medusa@${user}) == "active" ]]; then
  active=medusa
fi

if [[ $(systemctl is-active sickgear@${user}) == "active" ]]; then
  active=sickgear
fi

if [[ -n $active ]]; then
  echo "SickChill and Medusa and Sickgear cannot be active at the same time."
  echo "Do you want to disable $active and continue with the installation?"
  echo "Don't worry, your install will remain at /home/${user}/.$active"
  while true; do
  read -p "Do you want to disable $active? " yn
      case "$yn" in
          [Yy]|[Yy][Ee][Ss]) disable=yes; break;;
          [Nn]|[Nn][Oo]) disable=; break;;
          *) echo "Please answer yes or no.";;
      esac
  done
  if [[ $disable == "yes" ]]; then
    systemctl disable ${active}@${user}
    systemctl stop ${active}@${user}
  else
    exit 1
  fi
fi

apt-get -y -q update >> $log 2>&1
apt-get -y -q install git-core openssl libssl-dev python2.7 >> $log 2>&1

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
sudo git clone https://github.com/SickChill/SickChill.git  /home/$user/.sickchill >/dev/null 2>&1

chown -R $user:$user /home/$user/.sickchill

cat > /etc/systemd/system/sickchill@.service <<SSS
[Unit]
Description=SickChill
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=%I
Group=%I
ExecStart=/usr/bin/python /home/%I/.sickchill/SickBeard.py -q --daemon --nolaunch --datadir=/home/%I/.sickchill


[Install]
WantedBy=multi-user.target
SSS

  systemctl enable sickchill@$user > /dev/null 2>&1
  systemctl start sickchill@$user

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/sickchill.sh
  service nginx reload
fi

touch /install/.sickchill.lock
