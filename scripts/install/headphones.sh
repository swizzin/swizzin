#!/bin/bash
#
# swizzin install headphones
#
# swizzin Copyright (C) 2020 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#

user=$(cut -d: -f1 < /root/.master.info)
password=$(cut -d: -f2 < /root/.master.info)
codename=$(lsb_release -cs)
#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv

if [[ $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
	LIST='git python2.7-dev virtualenv python-virtualenv python-pip'
else
	LIST='git python2.7-dev'
fi

apt_install $LIST

if [[ ! $codename =~ ("xenial"|"stretch"|"buster"|"bionic") ]]; then
	python_getpip
fi

python2_venv ${user} headphones

PIP='wheel cheetah asn1'
echo_progress_start "Installing python dependencies"
/opt/.venv/headphones/bin/pip install $PIP >> "${log}" 2>&1
chown -R ${user}: /opt/.venv/headphones
echo_progress_done "Python dependencies installed"

echo_progress_start "Cloning Headphones source code"
git clone https://github.com/rembo10/headphones.git /opt/headphones >> "${log}" 2>&1
chown -R $user: /opt/headphones
echo_progress_done "Source cloned"

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/headphones.service << HEADSD
[Unit]
Description=Headphones
Wants=network.target network-online.target
After=network.target network-online.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=/opt/.venv/headphones/bin/python2 /opt/headphones/Headphones.py -d --pidfile /run/${user}/headphones.pid --datadir /opt/headphones --nolaunch --config /opt/headphones/config.ini --port 8004
PIDFile=/run/${user}/headphones.pid


[Install]
WantedBy=multi-user.target
HEADSD

systemctl enable -q --now headphones 2>&1 | tee -a $log
sleep 10
echo_progress_done "Systemd service installed"

if [[ -f /install/.nginx.lock ]]; then
	echo_progress_start "Installing nginx config"
	bash /usr/local/bin/swizzin/nginx/headphones.sh
	systemctl reload nginx
	echo_info "Please note headphones access url is: https://$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')/headphones/home"
fi
echo_success "Headphones installed"

touch /install/.headphones.lock
