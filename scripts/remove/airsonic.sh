#!/bin/bash

systemctl disable --now airsonic -q
deluser airsonic
sudo rm -rf /opt/airsonic

if [[ -f /install/.nginx.lock ]]; then
	rm /etc/nginx/apps/airsonic.conf
	systemctl reload nginx
fi

rm /install/.airsonic.lock
