#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)
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
