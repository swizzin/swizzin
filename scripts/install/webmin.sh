#! /bin/bash
# shellcheck disable=SC2024
# Webmin installer
# flying_sausages for swizzin 2020

_install_webmin() {
	echo_progress_start "Installing Webmin repo"
	echo "deb https://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
	wget http://www.webmin.com/jcameron-key.asc >> $log 2>&1
	apt-key add jcameron-key.asc >> $log 2>&1
	rm jcameron-key.asc
	echo_progress_done "Repo added"
	apt_update
	apt_install webmin
}

_install_webmin
if [[ -f /install/.nginx.lock ]]; then
	echo_progress_start "Configuring nginx"
	bash /etc/swizzin/scripts/nginx/webmin.sh
	echo_progress_done
fi

echo_success "Webmin installed"
echo_info "Please use any account with sudo permissions to log in"

touch /install/.webmin.lock
