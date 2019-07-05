#!/bin/bash
#
# [Install nextcloud package]
#
# Author:   liara for QuickBox.io
# Ported to swizzin by liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

inst=$(which mysql)
ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
if [[ ! -f /install/.nginx.lock ]]; then
  echo "ERROR: Web server not detected. Please install nginx and restart panel install."
  exit 1
else
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
  if [[ $(systemctl is-active mysql) != "active" ]]; then
    systemctl start mysql
  fi
  mysqladmin -u root password ${password}
fi
#Depends
apt-get install -y -q unzip php-mysql libxml2-dev php-common php-gd php-json php-curl  php-zip php-xml php-mbstring > /dev/null 2>&1
#a2enmod rewrite > /dev/null 2>&1
cd /tmp

#Nextcloud 16 no longer supports php7.0, so 15 is the last supported release for Debian 9
codename=$(lsb_release -cs)
if [[ $codename =~ ("stretch"|"jessie"|"xenial") ]]; then
  version="nextcloud-$(curl -s https://nextcloud.com/changelog/ | grep -A5 '"latest15"' | grep 'id=' | cut -d'"' -f2 | sed 's/-/./g')"
else
  version=latest
fi
wget -q https://download.nextcloud.com/server/releases/${version}.zip > /dev/null 2>&1
unzip ${version}.zip > /dev/null 2>&1
mv nextcloud /srv
rm -rf /tmp/${version}.zip

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

if [[ -f /lib/systemd/system/php7.3-fpm.service ]]; then
  sock=php7.3-fpm
elif [[ -f /lib/systemd/system/php7.2-fpm.service ]]; then
  sock=php7.2-fpm
elif [[ -f /lib/systemd/system/php7.1-fpm.service ]]; then
  sock=php7.1-fpm
else
  sock=php7.0-fpm
fi

cat > /etc/nginx/apps/nextcloud.conf <<EOF
location = /.well-known/carddav {
  return 301 \$scheme://\$host/nextcloud/remote.php/dav;
}
location = /.well-known/caldav {
  return 301 \$scheme://\$host/nextcloud/remote.php/dav;
}

location /.well-known/acme-challenge { }

location ^~ /nextcloud {

    # set max upload size
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    # Enable gzip but do not remove ETag headers
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    # Uncomment if your server is build with the ngx_pagespeed module
    # This module is currently not supported.
    #pagespeed off;

    location /nextcloud {
        rewrite ^ /nextcloud/index.php\$uri;
    }

    location ~ ^/nextcloud/(?:build|tests|config|lib|3rdparty|templates|data)/ {
        deny all;
    }
    location ~ ^/nextcloud/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

    location ~ ^/nextcloud/(?:index|remote|public|cron|core/ajax/update|status|ocs/v[12]|updater/.+|ocs-provider/.+)\.php(?:$|/) {
        fastcgi_split_path_info ^(.+\.php)(/.*)\$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param HTTPS on;
        #Avoid sending the security headers twice
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass unix:/run/php/$sock.sock;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    location ~ ^/nextcloud/(?:updater|ocs-provider)(?:\$|/) {
        try_files \$uri/ =404;
        index index.php;
    }

    # Adding the cache control header for js and css files
    # Make sure it is BELOW the PHP block
    location ~ \.(?:css|js|woff|svg|gif)\$ {
        try_files \$uri /nextcloud/index.php\$uri\$is_args\$args;
        add_header Cache-Control "public, max-age=15778463";
        # Add headers to serve security related headers  (It is intended
        # to have those duplicated to the ones above)
        # Before enabling Strict-Transport-Security headers please read
        # into this topic first.
        # add_header Strict-Transport-Security "max-age=15768000;
        # includeSubDomains; preload;";
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        # Optional: Don't log access to assets
        access_log off;
    }

    location ~ \.(?:png|html|ttf|ico|jpg|jpeg)\$ {
        try_files \$uri /nextcloud/index.php\$uri\$is_args\$args;
        # Optional: Don't log access to other assets
        access_log off;
    }
  }
EOF

mysql --user="root" --password="$password" --execute="CREATE DATABASE nextcloud;"
mysql --user="root" --password="$password" --execute="CREATE USER nextcloud@localhost IDENTIFIED BY '$nextpass';"
mysql --user="root" --password="$password" --execute="GRANT ALL PRIVILEGES ON nextcloud.* TO nextcloud@localhost;"
mysql --user="root" --password="$password" --execute="FLUSH PRIVILEGES;"

service nginx reload
touch /install/.nextcloud.lock

echo -e "Visit https://${ip}/nextcloud to finish installation."
echo -e "Database user: nextcloud"
echo -e "Database password: ${nextpass}"
echo -e "Database name: nextcloud"
fi
