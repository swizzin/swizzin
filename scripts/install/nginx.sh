#!/bin/bash
# nginx installer
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
distribution=$(lsb_release -is)
release=$(lsb_release -rs)
codename=$(lsb_release -cs)
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/dev/null"
fi

if [[ -n $(pidof apache2) ]]; then
  if [[ -z $apache2 ]]; then
    if (whiptail --title "apache2 conflict" --yesno --yes-button "Purge it!" --no-button "Disable it" "WARNING: The installer has detected that apache2 is already installed. To continue, the installer must either purge apache2 or disable it." 8 78) then
      apache2=purge
    else
      apache2=disable
    fi
  fi
  if [[ $apache2 == "purge" ]]; then
    echo "Purging apache2 ... "
    systemctl disable apache2 >> /dev/null 2>&1
    systemctl stop apache2
    apt-get -y -q purge apache2 >> ${log} 2>&1
  elif [[ $apache2 == "disable" ]]; then
    echo "Disabling apache2 ... "
    systemctl disable apache2 >> /dev/null 2>&1
    systemctl stop apache2
  fi
fi

if [[ $codename == "jessie" ]]; then
  echo "deb http://packages.dotdeb.org $(lsb_release -sc) all" > /etc/apt/sources.list.d/dotdeb-php7-$(lsb_release -sc).list
  echo "deb-src http://packages.dotdeb.org $(lsb_release -sc) all" >> /etc/apt/sources.list.d/dotdeb-php7-$(lsb_release -sc).list
  wget -q https://www.dotdeb.org/dotdeb.gpg
  apt-key add dotdeb.gpg >> /dev/null 2>&1
#  cat > /etc/apt/preferences.d/ssl <<EOP
#Package: *libssl*
#Pin: release o=debian
#Pin-Priority: 1000
#
#Package: *openssl*
#Pin: release o=debian
#Pin-Priority: 1000
#EOP
  geoip=php7.0-geoip
  apt-get -y -qq update
else
  geoip=php-geoip
fi

if [[ $codename =~ ("bionic"|"buster") ]]; then
  mcrypt=
else
  mcrypt=php-mcrypt
fi

apt-get -y -qq update
APT='nginx-extras subversion ssl-cert php-fpm libfcgi0ldbl php-cli php-dev php-xml php-curl php-xmlrpc php-json '"${mcrypt}"' php-mbstring php-opcache '"${geoip}"' php-xml'
for depends in $APT; do
apt-get -y install "$depends" >> $log 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depends}. That's probably not good..."; }
done

cd /etc/php
phpv=$(ls -d */ | cut -d/ -f1)
for version in $phpv; do
  sed -i -e "s/post_max_size = 8M/post_max_size = 64M/" \
          -e "s/upload_max_filesize = 2M/upload_max_filesize = 92M/" \
          -e "s/expose_php = On/expose_php = Off/" \
          -e "s/128M/768M/" \
          -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" \
          -e "s/;opcache.enable=0/opcache.enable=1/" \
          -e "s/;opcache.memory_consumption=64/opcache.memory_consumption=128/" \
          -e "s/;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/" \
          -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=240/" /etc/php/$version/fpm/php.ini
  phpenmod -v $version opcache
done

if [[ -f /lib/systemd/system/php7.3-fpm.service ]]; then
  sock=php7.3-fpm
elif [[ -f /lib/systemd/system/php7.2-fpm.service ]]; then
  sock=php7.2-fpm
elif [[ -f /lib/systemd/system/php7.1-fpm.service ]]; then
  sock=php7.1-fpm
else
  sock=php7.0-fpm
fi

rm -rf /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-enabled/default <<NGC
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  server_name _;

  location /.well-known {
    alias /srv/.well-known;
    allow all;
    default_type "text/plain";
    autoindex    on;
  }

  location / {
    return 301 https://\$host\$request_uri;
  }
}

# SSL configuration
server {
  listen 443 ssl default_server;
  listen [::]:443 ssl default_server;
  server_name _;
  ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
  ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
  include snippets/ssl-params.conf;
  client_max_body_size 40M;
  server_tokens off;
  root /srv/;

  index index.html index.php index.htm;

  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/$sock.sock;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
  }

  include /etc/nginx/apps/*;

  location ~ /\.ht {
    deny all;
  }

  location /fancyindex {

  }
}
NGC

mkdir -p /etc/nginx/ssl/
mkdir -p /etc/nginx/snippets/
mkdir -p /etc/nginx/apps/

cd /etc/nginx/ssl
openssl dhparam -out dhparam.pem 2048 >>$log 2>&1

cat > /etc/nginx/snippets/ssl-params.conf <<SSC
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
ssl_ecdh_curve secp384r1;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 127.0.0.1 valid=300s;
resolver_timeout 5s;
# Disable preloading HSTS for now.  You can use the commented out header line that includes
# the "preload" directive if you understand the implications.
#add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";

#add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
#add_header X-Frame-Options DENY;
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;

ssl_dhparam /etc/nginx/ssl/dhparam.pem;
SSC

cat > /etc/nginx/snippets/proxy.conf <<PROX
client_max_body_size 10m;
client_body_buffer_size 128k;

#Timeout if the real server is dead
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

# Advanced Proxy Config
send_timeout 5m;
proxy_read_timeout 240;
proxy_send_timeout 240;
proxy_connect_timeout 240;

# Basic Proxy Config
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto https;
#proxy_redirect  http://  \$scheme://;
proxy_http_version 1.1;
proxy_set_header Connection "";
proxy_cache_bypass \$cookie_session;
proxy_no_cache \$cookie_session;
proxy_buffers 32 4k;
PROX

svn export https://github.com/Naereen/Nginx-Fancyindex-Theme/trunk/Nginx-Fancyindex-Theme-dark /srv/fancyindex >> $log 2>&1
cat > /etc/nginx/snippets/fancyindex.conf <<FIC
fancyindex on;
fancyindex_localtime on;
fancyindex_exact_size off;
fancyindex_header "/fancyindex/header.html";
fancyindex_footer "/fancyindex/footer.html";
#fancyindex_ignore "examplefile.html"; # Ignored files will not show up in the directory listing, but will still be public. 
#fancyindex_ignore "Nginx-Fancyindex-Theme"; # Making sure folder where files are don't show up in the listing. 
fancyindex_name_length 255; # Maximum file name length in bytes, change as you like.
FIC
sed -i 's/href="\/[^\/]*/href="\/fancyindex/g' /srv/fancyindex/header.html
sed -i 's/src="\/[^\/]*/src="\/fancyindex/g' /srv/fancyindex/footer.html


locks=($(find /usr/local/bin/swizzin/nginx -type f -printf "%f\n" | cut -d "." -f 1 | sort -d -r))
for i in "${locks[@]}"; do
  app=${i}
  if [[ -f /install/.$app.lock ]]; then
    echo "Installing nginx config for $app"
    /usr/local/bin/swizzin/nginx/$app.sh
  fi
done

systemctl restart nginx

if [[ -f /lib/systemd/system/php7.3-fpm.service ]]; then
  systemctl restart php7.3-fpm
  if [[ $(systemctl is-active php7.2-fpm) == "active" ]]; then
    systemctl stop php7.2-fpm
    systemctl disable php7.2-fpm
  fi
  if [[ $(systemctl is-active php7.1-fpm) == "active" ]]; then
    systemctl stop php7.1-fpm
    systemctl disable php7.1-fpm
  fi
  if [[ $(systemctl is-active php7.0-fpm) == "active" ]]; then
    systemctl stop php7.0-fpm
    systemctl disable php7.0-fpm
  fi
elif [[ -f /lib/systemd/system/php7.2-fpm.service ]]; then
  systemctl restart php7.2-fpm
  if [[ $(systemctl is-active php7.2-fpm) == "active" ]]; then
    systemctl stop php7.2-fpm
    systemctl disable php7.2-fpm
  fi
  if [[ $(systemctl is-active php7.0-fpm) == "active" ]]; then
    systemctl stop php7.0-fpm
    systemctl disable php7.0-fpm
  fi
elif [[ -f /lib/systemd/system/php7.1-fpm.service ]]; then
  systemctl restart php7.1-fpm
  if [[ $(systemctl is-active php7.0-fpm) == "active" ]]; then
    systemctl stop php7.0-fpm
    systemctl disable php7.0-fpm
  fi
else
  systemctl restart php7.0-fpm
fi
touch /install/.nginx.lock
