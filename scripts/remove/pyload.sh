#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)

systemctl disable --now pyload >/dev/null 2>&1

rm /etc/systemd/system/pyload.service

rm -rf /home/${user}/pyload
rm -rf /home/${user}/.venv/pyload
if [ -z "$(ls -A /home/$user/.venv)" ]; then
   rm -rf  /home/$user/.venv
fi
rm -rf /etc/nginx/apps/pyload.conf
apt-get -y remove tesseract-ocr gocr rhino >/dev/null 2>&1
apt-get -y autoremove >/dev/null 2>&1
systemctl reload nginx > /dev/null 2>&1
rm /install/.pyload.lock



