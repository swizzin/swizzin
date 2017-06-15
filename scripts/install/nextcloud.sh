#!/bin/bash
#
# [Quick Box :: Install nextcloud package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | lizaSB
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

inst=$(which mysql)
ip=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')

echo "Please choose a password for the nextcloud mysql user."
read -s -p "Password: " 'nextpass'
#Check for existing mysql and install if not found
if [[ -n $inst ]]; then
  echo -n -e "Existing mysql server detected!\n"
  echo -n -e "Please enter mysql root password so that installation may continue:\n"
  read -s -p "Password: " 'password'
  echo -e "Please wait while nextcloud is installed ... "

else
  echo -n -e "No mysql server found! Setup will install. \n"
  echo -n -e "Please enter a mysql root password \n"
  while [ -z "$password" ]; do
    read -s -p "Password: " 'pass1'
    echo
    read -s -p "Re-enter password to verify: " 'pass2'
    if [ $pass1 = $pass2 ]; then
       password=$pass1
    else
       echo
       echo "Passwords do not match"
    fi
  done
  echo -e "Please wait while nextcloud is installed ... "
  DEBIAN_FRONTEND=non‌​interactive apt-get -y install mariadb-server > /dev/null 2>&1
  mysqladmin -u root password ${password}
fi
#Depends
apt-get install -y -q php7.0-mysql libxml2-dev php7.0-common php7.0-gd php7.0-json php7.0-curl  php7.0-zip php7.0-xml php7.0-mbstring > /dev/null 2>&1
a2enmod rewrite > /dev/null 2>&1
cd /root
wget -q https://download.nextcloud.com/server/releases/nextcloud-11.0.2.zip > /dev/null 2>&1
unzip nextcloud-11.0.2.zip > /dev/null 2>&1
mv nextcloud /srv

#Set permissions as per nextcloud
ocpath='/srv/nextcloud'
htuser='www-data'
htgroup='www-data'
rootuser='root'

mkdir -p $ocpath/data
mkdir -p $ocpath/assets
mkdir -p $ocpath/updater
find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750
chown -R ${rootuser}:${htgroup} ${ocpath}/
chown -R ${htuser}:${htgroup} ${ocpath}/apps/
chown -R ${htuser}:${htgroup} ${ocpath}/assets/
chown -R ${htuser}:${htgroup} ${ocpath}/config/
chown -R ${htuser}:${htgroup} ${ocpath}/data/
chown -R ${htuser}:${htgroup} ${ocpath}/themes/
chown -R ${htuser}:${htgroup} ${ocpath}/updater/
chmod +x ${ocpath}/occ
if [ -f ${ocpath}/.htaccess ]
then
 chmod 0644 ${ocpath}/.htaccess
 chown ${rootuser}:${htgroup} ${ocpath}/.htaccess
fi
if [ -f ${ocpath}/data/.htaccess ]
then
 chmod 0644 ${ocpath}/data/.htaccess
 chown ${rootuser}:${htgroup} ${ocpath}/data/.htaccess
fi

cat > /etc/apache2/sites-enabled/nextcloud.conf <<EOF
Alias /nextcloud "/srv/nextcloud/"

<Directory /srv/nextcloud/>
 Options +FollowSymlinks
 AllowOverride All
 Require all granted

<IfModule mod_dav.c>
 Dav off
</IfModule>

SetEnv HOME /srv/nextcloud
SetEnv HTTP_HOME /srv/nextcloud

</Directory>
EOF

mysql --user="root" --password="$password" --execute="CREATE DATABASE nextcloud;"
mysql --user="root" --password="$password" --execute="CREATE USER nextcloud@localhost IDENTIFIED BY '$nextpass';"
mysql --user="root" --password="$password" --execute="GRANT ALL PRIVILEGES ON nextcloud.* TO nextcloud@localhost;"
mysql --user="root" --password="$password" --execute="FLUSH PRIVILEGES;"

service apache2 reload
rm -rf /root/nextcloud*
touch /install/.nextcloud.lock

echo -e "Visit https://${ip}/nextcloud to finish installation."
echo -e "Database user: nextcloud"
echo -e "Database password: ${nextpass}"
echo -e "Database name: nextcloud"
