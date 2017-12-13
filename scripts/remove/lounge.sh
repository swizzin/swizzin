#!/bin/bash

systemctl disable lounge
systemctl stop lounge

npm uninstall -g thelounge --save

deluser lounge
rm -rf /home/lounge

rm -f /etc/systemd/system/lounge.service
rm -f /install/.lounge.lock