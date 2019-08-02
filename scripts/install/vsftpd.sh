#!/bin/bash
# vsftpd installer
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  log="/srv/panel/db/output.log"
else
  log="/dev/null"
fi

apt-get -y update >> $log 2>&1
apt-get -y install vsftpd ssl-cert>> $log 2>&1

cat > /etc/vsftpd.conf <<VSC
listen=NO
listen_ipv6=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
force_dot_files=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
utf8_filesystem=YES
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=YES
pam_service_name=vsftpd
secure_chroot_dir=/var/run/vsftpd/empty

#ascii_upload_enable=YES
#ascii_download_enable=YES
#ftpd_banner=Welcome to blah FTP service.

#############################################
#Uncomment these lines to enable FXP support#
#############################################
#pasv_promiscuous=YES
#port_promiscuous=YES

###################
#Set a custom port#
###################
#listen_port=
VSC

# Check for LE cert, and copy it if available.
chkhost="$(find /etc/nginx/ssl/* -maxdepth 1 -type d | cut -f 5 -d '/')"
if [[ -n $chkhost ]]; then
    defaulthost=$(grep -m1 "server_name" /etc/nginx/sites-enabled/default | awk '{print $2}' | sed 's/;//g')
    sed -i "s#rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem#rsa_cert_file=/etc/nginx/ssl/${defaulthost}/fullchain.pem#g" /etc/vsftpd.conf
    sed -i "s#rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key#rsa_private_key_file=/etc/nginx/ssl/${defaulthost}/key.pem#g" /etc/vsftpd.conf
fi

systemctl restart vsftpd

touch /install/.vsftpd.lock
