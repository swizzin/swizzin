#!/bin/bash
# Librespeed installer for swizzin
# Author: hwcltjn

if [[ ! -f /install/.nginx.lock ]]; then
  echo_error "Web server not detected. Please install nginx and restart panel install."
  exit 1
fi

lspdpath='/srv/librespeed'
htuser='www-data'
htgroup='www-data'

function _installLibreSpeed1() {
	mkdir $lspdpath
	echo_progress_start "Cloning librespeed source code"
	git clone https://github.com/librespeed/speedtest.git $lspdpath >/dev/null 2>&1
	cp $lspdpath/example-singleServer-gauges.html $lspdpath/index.html
	swizname=$(sed -ne '/server_name/{s/.*server_name //; s/[; ].*//; p; q}' /etc/nginx/sites-enabled/default)
	if [ ! -z "$swizname" ] && [ "$swizname" != "_" ]; then
		sed -i "s/LibreSpeed Example/LibreSpeed - $swizname/g" $lspdpath/index.html
	else
		sed -i "s/LibreSpeed Example/LibreSpeed/g" $lspdpath/index.html
	fi
	echo_progress_done "Source cloned"
}

function _installLibreSpeed2() {
	echo_progress_start "Setting permissions"
	touch /install/.librespeed.lock
	find ${lspdpath}/ -type f -print0 | xargs -0 chmod 0640
	find ${lspdpath}/ -type d -print0 | xargs -0 chmod 0750
	chown -R ${htuser}:${htgroup} ${lspdpath}/
	echo_progress_done "Permissions set"
}

function _installLibreSpeed3() {
  if [[ -f /install/.nginx.lock ]]; then
  echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/librespeed.sh
    systemctl reload nginx
	echo_progress_done "nginx configured"
  fi
}

function _installLibreSpeed4() {
    echo_success "LibreSpeed installed"
    sleep 5
    systemctl reload nginx
}

function _installLibreSpeed5() {
	exit
}

_installLibreSpeed1
_installLibreSpeed2
_installLibreSpeed3
_installLibreSpeed4
_installLibreSpeed5