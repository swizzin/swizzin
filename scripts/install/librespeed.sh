#!/bin/bash
# Librespeed installer for swizzin
# Author: hwcltjn

if [[ ! -f /install/.nginx.lock ]]; then
  echo "ERROR: Web server not detected. Please install nginx and restart panel install."
  exit 1
fi

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
else
  OUTTO="/root/logs/swizzin.log"
fi

lspdpath='/srv/librespeed'
htuser='www-data'
htgroup='www-data'

function _installLibreSpeed1() {
	mkdir $lspdpath
	git clone https://github.com/librespeed/speedtest.git $lspdpath >/dev/null 2>&1
	cp $lspdpath/example-singleServer-gauges.html $lspdpath/index.html
	swizname=$(sed -ne '/server_name/{s/.*server_name //; s/[; ].*//; p; q}' /etc/nginx/sites-enabled/default)
	if [ ! -z "$swizname" ] && [ "$swizname" != "_" ]; then
		sed -i "s/LibreSpeed Example/LibreSpeed - $swizname/g" $lspdpath/index.html
	else
		sed -i "s/LibreSpeed Example/LibreSpeed/g" $lspdpath/index.html
	fi
}

function _installLibreSpeed2() {
	touch /install/.librespeed.lock
	find ${lspdpath}/ -type f -print0 | xargs -0 chmod 0640
	find ${lspdpath}/ -type d -print0 | xargs -0 chmod 0750
	chown -R ${htuser}:${htgroup} ${lspdpath}/
}

function _installLibreSpeed3() {
  if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/librespeed.sh
    service nginx reload
  fi
}

function _installLibreSpeed4() {
    echo "LibreSpeed Install Complete!" >>"${OUTTO}" 2>&1;
    sleep 5
    service nginx reload
}

function _installLibreSpeed5() {
	exit
}

echo "Installing LibreSpeed ... " >>"${OUTTO}" 2>&1;_installLibreSpeed1
echo "Configuring LibreSpeed permissions ... " >>"${OUTTO}" 2>&1;_installLibreSpeed2
echo "Configuring LibreSpeed nginx configuration ... " >>"${OUTTO}" 2>&1;_installLibreSpeed3
echo "Reloading nginx ... " >>"${OUTTO}" 2>&1;_installLibreSpeed4

_installLibreSpeed5