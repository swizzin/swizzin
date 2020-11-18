#!/bin/bash
#
# Ombi installer
#
# Author:   QuickBox.IO | liara
# Ported for swizzin by liara
#
# QuickBox Copyright (C) 2016
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

function _depends() {
	echo_progress_start "Installing ombi apt sources"
	if [[ ! -f /etc/apt/sources.list.d/ombi.list ]]; then
		echo "deb http://repo.ombi.turd.me/stable/ jessie main" > /etc/apt/sources.list.d/ombi.list
		wget -qO - https://repo.ombi.turd.me/pubkey.txt | sudo apt-key add -
	fi
	apt_update
	echo_progress_done "Sources installed and refreshed"
}

function _install() {
	#cd /opt
	#curl -sL https://git.io/vKEJz | grep release | grep linux.tar.gz | cut -d "\"" -f 2 | sed -e 's/\/tidusjar/https:\/\/github.com\/tidusjar/g' | xargs wget --quiet -O Ombi.zip >/dev/null 2>&1
	#mkdir ombi
	#mv Ombi.zip ombi
	#cd ombi
	#unzip Ombi.zip >/dev/null 2>&1
	#rm Ombi.zip
	#cd /opt
	#chown -R ${user}: ombi
	apt_install ombi
}

function _services() {
	echo_progress_start "Installing systemd service"
	cat > /etc/systemd/system/ombi.service << OMB
[Unit]
Description=Ombi - PMS Requests System
After=network-online.target

[Service]
User=ombi
Group=nogroup
WorkingDirectory=/opt/Ombi/
ExecStart=/opt/Ombi/Ombi --baseurl /ombi --host http://0.0.0.0:3000 --storage /etc/Ombi
Type=simple
TimeoutStopSec=30
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
OMB

	touch /install/.ombi.lock
	echo_progress_done "Service installed"
	if [[ -f /install/.nginx.lock ]]; then
		echo_progress_start "Configuring nginx"
		bash /usr/local/bin/swizzin/nginx/ombi.sh
		systemctl reload nginx
		echo_progress_done "Nginx configured"
	fi
	echo_progress_start "Enabling and starting ombi"
	systemctl enable -q ombi 2>&1 | tee -a $log
	systemctl restart ombi
	echo_progress_done "Ombi started"
}

distribution=$(lsb_release -is)
user=$(cut -d: -f1 < /root/.master.info)

# echo -ne "Initializing plex ... $i\033[0K\r"

_depends
_install
_services
echo_success "Ombi installed"
