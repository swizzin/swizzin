#!/bin/bash

function update_nginx() {
codename=$(lsb_release -cs)
if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/dev/null"
fi

if [[ $codename =~ ("xenial"|"stretch") ]]; then
  mcrypt=php-mcrypt
else
  mcrypt=
fi

#Deprecate nginx-extras in favour of installing fancyindex alone
# (unless you use xenial)
if [[ ! $codename == "xenial" ]]; then
  if dpkg -s nginx-extras > /dev/null 2>&1; then
    apt_remove nginx-extras
    apt_install nginx libnginx-mod-http-fancyindex
    apt_autoremove
    rm $(ls -d /etc/nginx/modules-enabled/*.removed)
    systemctl reload nginx
  fi
fi

APT="php-fpm php-cli php-dev php-xml php-curl php-xmlrpc php-json ${mcrypt} php-mbstring php-opcache php-geoip php-xml"
apt_install $APT

cd /etc/php
phpv=$(ls -d */ | cut -d/ -f1)
if [[ $phpv =~ "7.1" ]]; then
  if [[ $phpv =~ "7.0" ]]; then
    apt_remove purge php7.0-fpm
  fi
fi

. /etc/swizzin/sources/functions/php
phpversion=$(php_service_version)
sock="php${phpversion}-fpm"

for version in $phpv; do
  if [[ -f /etc/php/$version/fpm/php.ini ]]; then
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
  fi
done

if [[ ! -f /etc/nginx/modules-enabled/50-mod-http-fancyindex.conf ]]; then
  mkdir -p /etc/nginx/modules-enabled/
  ln -s /usr/share/nginx/modules-available/mod-http-fancyindex.conf /etc/nginx/modules-enabled/50-mod-http-fancyindex.conf
fi

phpversion=$(php_service_version)

fcgis=($(find /etc/nginx -type f -exec grep -l "fastcgi_pass unix:/run/php/" {} \;))
err=()
for f in ${fcgis[@]}; do
  err+=($(grep -L "fastcgi_pass unix:/run/php/php${phpversion}-fpm.sock" $f))
done
for fix in ${err[@]}; do
  sed -i "s/fastcgi_pass .*/fastcgi_pass unix:\/run\/php\/php${phpversion}-fpm.sock;/g" $fix
done

if grep -q -e "-dark" -e "Nginx-Fancyindex" /srv/fancyindex/header.html; then
  sed -i 's/href="\/[^\/]*/href="\/fancyindex/g' /srv/fancyindex/header.html
fi

if grep -q "Nginx-Fancyindex" /srv/fancyindex/footer.html; then
  sed -i 's/src="\/[^\/]*/src="\/fancyindex/g' /srv/fancyindex/footer.html
fi

if grep -q "php" /etc/nginx/apps/rindex.conf; then
  :
else
  cat > /etc/nginx/apps/rindex.conf <<EOR
location /rtorrent.downloads {
  alias /home/\$remote_user/torrents/rtorrent;
  include /etc/nginx/snippets/fancyindex.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;
  
  location ~* \.php$ {

  } 
}
EOR
fi

if grep -q "php" /etc/nginx/apps/dindex.conf; then
  :
else
  cat > /etc/nginx/apps/dindex.conf <<DIN
location /deluge.downloads {
  alias /home/\$remote_user/torrents/deluge;
  include /etc/nginx/snippets/fancyindex.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;

  location ~* \.php$ {

  } 
}
DIN
fi

. /etc/swizzin/sources/functions/php
restart_php_fpm
systemctl reload nginx
}

if [[ -f /install/.nginx.lock ]]; then update_nginx; fi