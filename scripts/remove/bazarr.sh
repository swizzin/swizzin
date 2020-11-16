#!/bin/bash
user=$(_get_master_username)
systemctl disable --now -q bazarr

rm -rf /opt/bazarr
rm -rf /opt/.venv/bazarr
if [ -z "$(ls -A /home/$user/.venv)" ]; then
	rm -rf /opt/.venv
fi
rm -rf /etc/nginx/apps/bazarr.conf
rm -rf /install/.bazarr.lock
rm -rf /etc/systemd/system/bazarr.service
systemctl reload nginx
