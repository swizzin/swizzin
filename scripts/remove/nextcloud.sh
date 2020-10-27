#!/bin/bash
# nextcloud uninstaller
host=$(mysql --execute="select host from mysql.user where user = 'nextcloud';" | grep -E "localhost|127.0.0.1")
echo_info "Removing all Nextcloud data"
mysql --execute="DROP DATABASE nextcloud;" && mysql --execute="DROP USER nextcloud@$host;"
if [[ $? != "0" ]]; then 
    echo_error "MySQL Drop failed. Please try again or investigate"
    exit 1
fi
crontab -l -u www-data | grep -v nextcloud > /tmp/.lol
crontab -u www-data /tmp/.lol
rm -rf /srv/nextcloud
rm /etc/nginx/apps/nextcloud.conf
systemctl reload nginx

rm /install/.nextcloud.lock