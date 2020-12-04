#!/bin/bash
# Ombi installer
# Swizzin gplv3 and all that

function _sources() {
	echo_progress_start "Installing ombi apt sources"
	echo "deb http://repo.ombi.turd.me/stable/ jessie main" > /etc/apt/sources.list.d/ombi.list
	wget -qO - https://repo.ombi.turd.me/pubkey.txt | apt-key add - >> "$log" 2>&1
	echo_progress_done "Sources installed"
	apt_update
}

function _install() {
	apt_install ombi
	systemctl enable --now -q ombi
}

function _nginx() {
	if [[ -f /install/.nginx.lock ]]; then
		echo_progress_start "Configuring nginx"
		bash /usr/local/bin/swizzin/nginx/ombi.sh
		systemctl reload nginx
		echo_progress_done "Nginx configured"
	else
		echo_info "Ombi is accessible under port 5000"
	fi

}

_sources
_install
_nginx
touch /install/.ombi.lock
echo_success "Ombi installed"
