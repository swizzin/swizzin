#!/bin/bash
#VSFTPd deyeeter by flying sausages for swizzin 2020

log=/root/logs/swizzin.log

apt_remove vsftpd -y >> $log 2>&1
rm /etc/vsftpd.conf

rm /install/.vsftpd.lock