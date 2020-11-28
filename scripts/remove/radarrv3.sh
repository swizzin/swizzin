#!/bin/bash
systemctl disable --now -q radarr
rm -rf /etc/systemd/system/radarr.service
systemctl daemon-reload -q
rm -rf /opt/Radarr

if [[ -f /install/.nginx.lock ]]; then
	rm -rf /etc/nginx/apps/radarrv3.conf
	systemctl reload nginx
fi

rm -rf /install/.radarrv3.lock
