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

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

inst=$(which mysql)
ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
if [[ ! -f /install/.nginx.lock ]]; then
  echo "ERROR: Web server not detected. Please install nginx and restart panel install."
  exit 1
fi

#Check for existing mysql and install if not found
if [[ -n $inst ]]; then
  echo -n -e "Existing MySQL server detected!\n"
else
  echo -n -e "No MySQL server found! Setup will install. \n"
  echo -n -e "Please enter a MySQL root password \n"
  while [ -z "$password" ]; do
    read -r -s -p "Password: " 'pass1'
    echo
    read -r -s -p "Re-enter password to verify: " 'pass2'
    echo
    if [ "$pass1" = "$pass2" ]; then
       password=$pass1
    else
       echo "Passwords do not match. Please try again."
    fi
  done
  installmysql=true
fi

echo "Please choose a password for the Nextcloud MySQL user."
read -r -s -p "Password: " 'nextpass'
echo

if [[ $installmysql = "true" ]]; then 
  echo "Installing MySQL*" #MariaDB yeeee
  DEBIAN_FRONTEND=non‌​interactive apt-get -y install mariadb-server >> $log 2>&1
  if [[ $(systemctl is-active MySQL) != "active" ]]; then
    systemctl start mysql
  fi
  mysqladmin -u root password "${password}"
fi


mysql --execute="CREATE DATABASE nextcloud;"
mysql --execute="CREATE USER nextcloud@localhost IDENTIFIED BY '$nextpass';"
mysql --execute="GRANT ALL PRIVILEGES ON nextcloud.* TO nextcloud@localhost;"
mysql --execute="FLUSH PRIVILEGES;"


#Depends
echo "Installing dependencies"
apt-get install -y -q unzip php-mysql libxml2-dev php-common php-gd php-json php-curl php-imagick php-intl php-zip php-xml php-mbstring >> $log 2>&1
#a2enmod rewrite >> $log 2>&1

#Nextcloud 16 no longer supports php7.0, so 15 is the last supported release for Debian 9
codename=$(lsb_release -cs)
if [[ $codename =~ ("stretch"|"xenial") ]]; then
  version="nextcloud-$(curl -s https://nextcloud.com/changelog/ | grep -A5 '"latest15"' | grep 'id=' | cut -d'"' -f2 | sed 's/-/./g')"
else
  version=latest
fi
echo "Downloading Nextcloud source files"
wget -q https://download.nextcloud.com/server/releases/${version}.zip -O /tmp/nextcloud.zip >> $log 2>&1
unzip /tmp/nextcloud.zip -d /srv >> $log 2>&1
rm -rf /tmp/nextcloud.zip

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

# shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php
phpversion=$(php_service_version)
sock="php${phpversion}-fpm"

cat > /etc/nginx/apps/nextcloud.conf <<EOF
# The following 2 rules are only needed for the user_webfinger app.
# Uncomment it if you're planning to use this app.
#rewrite ^/.well-known/host-meta /nextcloud/public.php?service=host-meta last;
#rewrite ^/.well-known/host-meta.json /nextcloud/public.php?service=host-meta-json last;

# The following rule is only needed for the Social app.
# Uncomment it if you're planning to use this app.
#rewrite ^/.well-known/webfinger /nextcloud/public.php?service=webfinger last;

location = /.well-known/carddav {
  return 301 \$scheme://\$host:\$server_port/nextcloud/remote.php/dav;
}
location = /.well-known/caldav {
  return 301 \$scheme://\$host:\$server_port/nextcloud/remote.php/dav;
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
        rewrite ^ /nextcloud/index.php;
    }

    location ~ ^\/nextcloud\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
        deny all;
    }
    location ~ ^\/nextcloud\/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

    location ~ ^\/nextcloud\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:\$|\/) {
        fastcgi_split_path_info ^(.+?\.php)(\/.*|)\$;
        set \$path_info \$fastcgi_path_info;
        try_files \$fastcgi_script_name =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$path_info;
        fastcgi_param HTTPS on;
        # Avoid sending the security headers twice
        fastcgi_param modHeadersAvailable true;
        # Enable pretty urls
        fastcgi_param front_controller_active true;
        fastcgi_pass unix:/run/php/$sock.sock;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    location ~ ^\/nextcloud\/(?:updater|oc[ms]-provider)(?:\$|\/) {
        try_files \$uri/ =404;
        index index.php;
    }

    # Adding the cache control header for js, css and map files
    # Make sure it is BELOW the PHP block
    location ~ ^\/nextcloud\/.+[^\/]\.(?:css|js|woff2?|svg|gif|map)\$ {
        try_files \$uri /nextcloud/index.php\$request_uri;
        add_header Cache-Control "public, max-age=15778463";
        # Add headers to serve security related headers  (It is intended
        # to have those duplicated to the ones above)
        # Before enabling Strict-Transport-Security headers please read
        # into this topic first.
        #add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;
        #
        # WARNING: Only add the preload option once you read about
        # the consequences in https://hstspreload.org/. This option
        # will add the domain to a hardcoded list that is shipped
        # in all major browsers and getting removed from this list
        # could take several months.
        add_header Referrer-Policy "no-referrer" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Download-Options "noopen" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Permitted-Cross-Domain-Policies "none" always;
        add_header X-Robots-Tag "none" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # Optional: Don't log access to assets
        access_log off;
    }

    location ~ ^\/nextcloud\/.+[^\/]\.(?:png|html|ttf|ico|jpg|jpeg|bcmap)\$ {
        try_files \$uri /nextcloud/index.php\$request_uri;
        # Optional: Don't log access to other assets
        access_log off;
    }
}
EOF

systemctl reload nginx
touch /install/.nextcloud.lock

# echo -e "Visit https://${ip}/nextcloud to finish installation. Use the values below"
# echo -e "   Database user: nextcloud"
# echo -e "   Database password: ${nextpass}"
# echo -e "   Database name: nextcloud"

echo "Setting up Nextcloud"
# shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
masteruser=$(cut -d: -f1 < /root/.master.info)
masterpass=$(_get_user_password "$masteruser")



cd $ocpath || : #shut up linter
sudo -u www-data php occ  maintenance:install \
--database "mysql" \
--database-name "nextcloud"  \
--database-user "nextcloud" \
--database-pass "$nextpass" \
--admin-user "$masteruser" \
--admin-pass "$masterpass" 2>&1 | tee -a $log

# i=$(sudo -u www-data php occ config:system:get trusted_domains | wc -l)

# Possible woraround to skip this here, but I'd rather avoid this to be honest as we're exposed to the internet in most cases here.
# https://github.com/owncloud/core/issues/21922#issuecomment-247605455
i=1
sudo -u www-data php occ config:system:set trusted_domains "$i" --value="localhost" 2>&1 | tee -a $log
((i++))
sudo -u www-data php occ config:system:set trusted_domains "$i" --value="$ip" 2>&1 | tee -a $log
((i++))
sudo -u www-data php occ config:system:set trusted_domains "$i" --value="$(hostname)" 2>&1 | tee -a $log
((i++))
sudo -u www-data php occ config:system:set trusted_domains "$i" --value="$(hostname -f)" 2>&1 | tee -a $log

# shellcheck disable=SC2013
for value in $(grep server_name /etc/nginx/sites-enabled/default | cut -d' ' -f 4 | cut -d\; -f 1); do
  if [[ $value != "_" ]]; then 
    sudo -u www-data php occ config:system:set trusted_domains "$i" --value="$value" | tee -a $log
    ((i++))
  fi
done

#All users but the master user
users=($(cut -d: -f1 < /etc/htpasswd |sed "/^$masteruser\b/Id"))
# shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
for u in "${users[@]}"; do
    OC_PASS=$(_get_user_password "$u")
    export OC_PASS
    #TODO decide what happens wih the stdout from this
    su -s /bin/sh www-data -c "php occ user:add --password-from-env --display-name=${u} --group='users' ${u}" 2>&1 | tee -a $log
    unset OC_PASS
done
echo "Please log in using your master credentials."


