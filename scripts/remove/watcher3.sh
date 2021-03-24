#!/bin/bash
# watcher3 removal script

user=$(cut -d: -f1 </root/.master.info)

systemctl disable --now watcher3@$user

rm -rf /opt/watcher3
rm -f /etc/nginx/apps/watcher3.conf >/dev/null 2>&1
rm -f /install/.watcher3.lock
rm -f /etc/systemd/system/watcher3@.service
