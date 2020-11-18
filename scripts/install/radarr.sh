#!/bin/bash
#
# [Quick Box :: Install Radarr package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/QB
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   PastaGringo | KarmaPoliceT2
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#################################################################################
function _string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15; }
#################################################################################

function _installRadarrDependencies() {
	echo_progress_start "Installing dependencies"
	mono_repo_setup
	echo_progress_done
}

function _installRadarrCode() {
	apt_install libmono-cil-dev curl mediainfo
	echo_progress_start "Installing Radarr"
	if [[ ! -d /opt ]]; then mkdir /opt; fi
	cd /opt
	wget $(curl -s https://api.github.com/repos/Radarr/Radarr/releases | grep linux.tar.gz | grep browser_download_url | head -1 | cut -d \" -f 4) > /dev/null 2>&1
	tar -xvzf Radarr.*.linux.tar.gz > /dev/null 2>&1
	rm -rf /opt/Radarr.*.linux.tar.gz
	echo_progress_done "Radarr installed"
	touch /install/.radarr.lock
}

function _installRadarrConfigure() {
	# output to box
	echo_progress_start "Installing systemd service"
	cat > /etc/systemd/system/radarr.service << EOF
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
User=${username}
Group=${username}
Type=simple
ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

	mkdir -p /home/${username}/.config
	chown -R ${username}:${username} /home/${username}/.config
	#  chmod 775 /home/${username}/.config
	chown -R ${username}:${username} /opt/Radarr/
	systemctl daemon-reload
	systemctl enable -q radarr.service 2>&1 | tee -a $log
	systemctl start radarr.service
	echo_progress_done "Radarr started"

	if [[ -f /install/.nginx.lock ]]; then
		echo_progress_start "Configuring nginx"
		sleep 10
		bash /usr/local/bin/swizzin/nginx/radarr.sh
		systemctl reload nginx
		echo_progress_done
	fi
}

username=$(cut -d: -f1 < /root/.master.info)
distribution=$(lsb_release -is)
version=$(lsb_release -cs)
. /etc/swizzin/sources/functions/mono
ip=$(curl -s http://whatismyip.akamai.com)

# _installRadarrIntro
_installRadarrDependencies
_installRadarrCode
_installRadarrConfigure
echo_success "Radarr installed"
