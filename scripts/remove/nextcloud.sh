#!/bin/bash
# nextcloud uninstaller
echo -n -e "Please enter mysql root password so that nextcloud database and user can be dropped.\n"
read -s -p "Password: " 'password'
rm -rf /srv/nextcloud
rm /etc/nginx/apps/nextcloud.conf
service nginx reload
mysql --user="root" --password="$password" --execute="DROP DATABASE nextcloud;"
mysql --user="root" --password="$password" --execute="DROP USER nextcloud@localhost;"
rm /install/.nextcloud.lock
