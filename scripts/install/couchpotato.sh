#!/bin/bash
#
# CouchPotato Installer by liara
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi
user=$(cut -d: -f1 < /root/.master.info)
codename=$(lsb_release -cs)


if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
  LIST='git python2-dev virtualenv'
else
  LIST='git python2-dev'
fi

apt-get -y -q update >>"${log}" 2>&1
for depend in $LIST; do
  apt-get -qq -y install $depend >>"${log}" 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depend}. That's probably not good..."; }
done

if [[ ! $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
  . /etc/swizzin/sources/functions/pyenv
  python_getpip
  pip install virtualenv >>"${log}" 2>&1
fi

echo "Setting up the couchpotato venv ..."
mkdir -p /home/${user}/.venv
chown ${user}: /home/${user}/.venv
python2 -m virtualenv /home/${user}/.venv/couchpotato >>"${log}" 2>&1
/home/${user}/.venv/couchpotato/bin/pip install pyOpenSSL lxml >>"${log}" 2>&1

git clone https://github.com/CouchPotato/CouchPotatoServer.git /home/${user}/couchpotato >> ${log} 2>&1 || { echo "git clone for couchpotato failed"; exit 1; }
chown ${user}: -R /home/${user}/couchpotato
chown ${user}: -R /home/${user}/.venv/couchpotato


cat > /etc/systemd/system/couchpotato.service <<CPSD
Description=CouchPotato
After=syslog.target network.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=/home/${user}/.venv/couchpotato/bin/python2 /home/${user}/couchpotato/CouchPotato.py --daemon
GuessMainPID=no
ExecStop=-/bin/kill -HUP


[Install]
WantedBy=multi-user.target
CPSD

systemctl enable --now couchpotato >> ${log} 2>&1

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/couchpotato.sh
  systemctl reload nginx
fi

touch /install/.couchpotato.lock

