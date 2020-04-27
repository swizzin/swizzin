#!/bin/bash
#
# swizzin Copyright (C) 2020 swizzin.ltd
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

for depend in $LIST; do
  apt-get -y update >>"${log}" 2>&1
  apt-get -qq -y install $depend >>"${log}" 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depend}. That's probably not good..."; }
done

if [[ ! $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
  . /etc/swizzin/sources/functions/pyenv
  python_getpip
  pip install -m virtualenv >>"${log}" 2>&1
fi

echo "Setting up the nzbhydra venv ..."
mkdir -p /home/${user}/.venv
chown ${user}: /home/${user}/.venv
python2 -m virtualenv /home/${user}/.venv/nzbhydra >>"${log}" 2>&1
chown ${user}: -R /home/${user}/.venv/nzbhydra

##echo >>"${log}" 2>&1;
echo "Cloning NZBHydra ... "
git clone -q https://github.com/theotherp/nzbhydra.git /home/${user}/nzbhydra
chown ${user}: -R /home/${user}/nzbhydra

mkdir -p /home/${user}/.config/nzbhydra

chown ${user}: /home/${user}/.config
chown ${user}: /home/${user}/.config/nzbhydra

cat > /etc/systemd/system/nzbhydra.service <<NZBH
[Unit]
Description=NZBHydra
Documentation=https://github.com/theotherp/nzbhydra
After=syslog.target network.target

[Service]
Type=forking
KillMode=control-group
User=${user}
Group=${user}
ExecStart=/home/${user}/.venv/nzbhydra/bin/python2 /home/${user}/nzbhydra/nzbhydra.py --daemon --nobrowser --pidfile /home/${user}/nzbhydra/nzbhydra.pid --logfile /home/${user}/.config/nzbhydra/nzbhydra.log --database /home/${user}/.config/nzbhydra/nzbhydra.db --config /home/${user}/.config/nzbhydra/settings.cfg
GuessMainPID=no
ExecStop=-/bin/kill -HUP
Restart=on-failure

[Install]
WantedBy=multi-user.target
NZBH

systemctl enable --now nzbhydra >> ${log} 2>&1

if [[ -f /install/.nginx.lock ]]; then
  sleep 30
  bash /usr/local/bin/swizzin/nginx/nzbhydra.sh
  systemctl reload nginx
fi

touch /install/.nzbhydra.lock

