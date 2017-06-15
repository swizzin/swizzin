#!/bin/bash

APT='nginx-full php7.0 php7.0-cli php7.0-fpm php7.0-dev php7.0-curl php7.0-xmlrpc php7.0-json php7.0-mcrypt php7.0-opcache php-geoip'
for depends in $APT; do
apt-get -qq -y --yes --force-yes install "$depends" >/dev/null 2>&1 || (echo "APT-GET could not find all the required sources. Script Ending." && echo "${warning}" && exit 1)
done

sed -i -e "s/post_max_size = 8M/post_max_size = 64M/" \
         -e "s/upload_max_filesize = 2M/upload_max_filesize = 92M/" \
         -e "s/expose_php = On/expose_php = Off/" \
         -e "s/128M/768M/" \
         -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" \
         -e "s/;opcache.enable=0/opcache.enable=1/" \
         -e "s/;opcache.memory_consumption=64/opcache.memory_consumption=128/" \
         -e "s/;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/" \
         -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=240/" /etc/php/7.0/fpm/php.ini
phpenmod -v 7.0 opcache

rm -rf /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-enabled/default <<NGC
server {
listen 80 default_server;
listen [::]:80 default_server;
server_name serverbabe.io;
return 301 https://$server_name$request_uri;
}

# SSL configuration
server {
listen 443 ssl default_server;
listen [::]:443 ssl default_server;
ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
include snippets/ssl-params.conf;
client_max_body_size 20M;
server_tokens off;
root /srv/;

index off;



location / {
  # First attempt to serve request as file, then
  # as directory, then fall back to displaying a 404.
  #try_files $uri $uri/ =404;
  try_files $uri $uri/ /index.php$is_args$args;
}

location = /favicon.ico { log_not_found off; access_log off; }
location = /robots.txt { log_not_found off; access_log off; allow all; }
location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
  expires max;
  log_not_found off;
}
# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
#
location ~ \.php$ {
  include snippets/fastcgi-php.conf;

  # With php7.0-cgi alone:
#	fastcgi_pass 127.0.0.1:9000;
#	# With php7.0-fpm:
  fastcgi_pass unix:/run/php/php7.0-fpm.sock;
}

# deny access to .htaccess files, if Apache's document root
# concurs with nginx's one
#
location ~ /\.ht {
  deny all;
}


}
NGC

mkdir -p /etc/nginx/ssl/
mkdir -p /etc/nginx/snippets/

cd /etc/nginx/ssl
openssl dhparam -out dhparam.pem 2048

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

add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
#add_header X-Frame-Options DENY;
add_header X-Frame-Options SAMEORIGIN;
add_header X-Content-Type-Options nosniff;

ssl_dhparam /etc/nginx/ssl/dhparam.pem;
SSC
