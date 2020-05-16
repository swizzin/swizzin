#!/bin/bash
# nextcloud uninstaller
echo -n -e "Please enter mysql root password so that nextcloud database and user can be dropped.\n"
read -r -s -p "Password: " 'password'
echo
host=$(mysql -u root --password="$password" --execute="select host from mysql.user where user = 'nextcloud';" | grep -E "localhost|127.0.0.1")
mysql --execute="DROP DATABASE nextcloud;"
mysql --execute="DROP USER nextcloud@$host;"
if [[ $? != "0" ]]; then 
    echo "MySQL Drop failed. Please try again or investigate"
    exit 1
fi
rm -rf /srv/nextcloud
rm /etc/nginx/apps/nextcloud.conf
systemctl reload nginx

rm /install/.nextcloud.lock