#!/bin/bash
# nextcloud uninstaller
echo -n -e "Please enter mysql root password so that nextcloud database and user can be dropped.\n"
read -s -p "Password: " 'password'
rm -rf /srv/nextcloud
rm /etc/nginx/apps/nextcloud.conf
service nginx reload
mysql --user="root" --password="$password" --execute="DROP DATABASE nextcloud;"
mysql --user="root" --password="$password" --execute="DROP USER nextcloud@127.0.0.1;"
rm /install/.nextcloud.lock
