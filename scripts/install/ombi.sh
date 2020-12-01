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

function _sources() {
	echo_progress_start "Installing ombi apt sources"
	echo "deb http://repo.ombi.turd.me/stable/ jessie main" > /etc/apt/sources.list.d/ombi.list
	wget -qO - https://repo.ombi.turd.me/pubkey.txt | sudo apt-key add -
	echo_progress_done "Sources installed"
	apt_update
}

function _install() {
	apt_install ombi
}

function _nginx() {

	if [[ -f /install/.nginx.lock ]]; then
		echo_progress_start "Configuring nginx"
		bash /usr/local/bin/swizzin/nginx/ombi.sh
		systemctl reload nginx
		echo_progress_done "Nginx configured"
	fi

}

_sources
_install
_nginx
touch /install/.ombi.lock
echo_success "Ombi installed"
