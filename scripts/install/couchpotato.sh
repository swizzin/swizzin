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
. /etc/swizzin/sources/functions/pyenv


if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
  LIST='git python2.7-dev python-virtualenv virtualenv'
else
  LIST='git python2.7-dev'
fi

apt_install $LIST

if [[ ! $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
  python_getpip
fi


python2_venv ${user} couchpotato
/opt/.venv/couchpotato/bin/pip install pyOpenSSL lxml >>"${log}" 2>&1

git clone https://github.com/CouchPotato/CouchPotatoServer.git /opt/couchpotato >> ${log} 2>&1 || { echo "git clone for couchpotato failed"; exit 1; }
chown ${user}: -R /opt/couchpotato
chown ${user}: -R /opt/.venv/couchpotato
mkdir -p /opt/.config/couchpotato
chown ${user}: /opt/.config
chown ${user}: /opt/.config/couchpotato


cat > /etc/systemd/system/couchpotato.service <<CPSD
[Unit]
Description=CouchPotato
After=syslog.target network.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=/opt/.venv/couchpotato/bin/python2 /opt/couchpotato/CouchPotato.py --daemon --data_dir /home/${user}/.config/couchpotato
GuessMainPID=no

[Install]
WantedBy=multi-user.target
CPSD

systemctl enable --now couchpotato >> ${log} 2>&1

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/couchpotato.sh
  systemctl reload nginx
fi

touch /install/.couchpotato.lock

