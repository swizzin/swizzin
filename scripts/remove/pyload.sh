#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)

systemctl disable --now pyload >/dev/null 2>&1

rm /etc/systemd/system/pyload.service

rm -rf /opt/pyload
rm -rf /opt/.venv/pyload
if [ -z "$(ls -A /opt/.venv)" ]; then
   rm -rf  /opt/.venv
fi
rm -rf /etc/nginx/apps/pyload.conf
apt-get -y remove tesseract-ocr gocr rhino >/dev/null 2>&1
apt-get -y autoremove >/dev/null 2>&1
systemctl reload nginx > /dev/null 2>&1
rm /install/.pyload.lock



