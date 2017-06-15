#!/bin/bash
#
# [Quick Box :: Install Let's Encrypt package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   Neilpang | adaptive build QuickBox.IO ~JMSolo
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

service apache2 stop

cd /root
mkdir -p /etc/apache2/ssl/{site,certs}
git clone https://github.com/Neilpang/acme.sh.git acme.sh-master
cd /root/acme.sh-master

echo -ne "Please enter an administrator email: " ; read EMAIL
echo -ne "Please enter a valid domain: " ; read DOMAIN

./acme.sh --install --accountconf /etc/apache2/ssl/site/$DOMAIN.conf --accountkey /etc/apache2/ssl/site/$DOMAIN.key --accountemail "$EMAIL"
./acme.sh --issue --standalone --keypath /etc/apache2/ssl/certs/$DOMAIN-ssl.key --fullchainpath /etc/apache2/ssl/certs/$DOMAIN-ssl.pem -d $DOMAIN

sed -i -e "s/SSLCertificateFile \/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/SSLCertificateFile \/etc\/apache2\/ssl\/certs\/$DOMAIN-ssl.pem/g" /etc/apache2/sites-enabled/default-ssl.conf
sed -i -e "s/SSLCertificateKeyFile \/etc\/ssl\/private\/ssl-cert-snakeoil.key/SSLCertificateKeyFile \/etc\/apache2\/ssl\/certs\/$DOMAIN-ssl.key/g" /etc/apache2/sites-enabled/default-ssl.conf

line="30 2 * * 1 "~/acme.sh"/acme.sh --cron --home "~/acme.sh" > /dev/null"
(crontab -u root -l; echo "$line" ) | crontab -u root -

service apache2 restart
