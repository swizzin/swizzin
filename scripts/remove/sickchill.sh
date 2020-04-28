#!/bin/bash
#
# Uninstaller for sickchill
#
user=$(cut -d: -f1 < /root/.master.info)
systemctl disable --now sickchill
rm -rf /home/$user/sickchill
rm -rf /home/$user/.venv/sickchill
if [ -z "$(ls -A /home/$user/.venv)" ]; then
   rm -rf  /home/$user/.venv
fi
rm /etc/nginx/apps/sickchill.conf > /dev/null 2>&1
rm /etc/systemd/sickchill.service > /dev/null 2>&1
systemctl reload nginx
rm -f /install/.sickchill.lock