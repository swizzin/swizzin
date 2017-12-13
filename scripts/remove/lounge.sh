#!/bin/bash

systemctl disable lounge >> /dev/null 2>&1
systemctl stop lounge

npm uninstall -g thelounge --save >> /dev/null 2>&1

deluser lounge >> /dev/null 2>&1
rm -rf /home/lounge

rm -f /etc/systemd/system/lounge.service
rm -f /install/.lounge.lock