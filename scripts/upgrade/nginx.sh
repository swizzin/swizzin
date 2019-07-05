#!/bin/bash
# A script to reset your nginx configs to the latest versions "upgrading" nginx
# Beware, this script *will* overwrite any personal modifications you have made.
# Author: liara

hostname=$(cat /etc/nginx/sites-enabled/default | grep -m1 -i server_name | sed 's/server_name//g' | sed 's/ //'g | sed 's/;//g')
locks=($(find /usr/local/bin/swizzin/nginx -type f -printf "%f\n" | cut -d "." -f 1 | sort -d -r))

if [[ ! -f /install/.nginx.lock ]]; then
  echo "nginx doesn't appear to be installed. What do you hope to accomplish by running this script?"
  exit 1
fi

for i in "${locks[@]}"; do
  app=${i}
  if [[ -f /install/.$app.lock ]]; then
    rm -f /etc/nginx/apps/$app.conf
  fi
done

rm -f /etc/nginx/apps/dindex.conf
rm -f /etc/nginx/apps/rindex.conf
rm -f /etc/nginx/apps/*.scgi.conf

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/conf.d/*
rm -f /etc/nginx/snippets/{ssl-params,proxy,fancyindex}.conf

if [[ -f /lib/systemd/system/php7.3-fpm.service ]]; then
  sock=php7.3-fpm
elif [[ -f /lib/systemd/system/php7.2-fpm.service ]]; then
  sock=php7.2-fpm
elif [[ -f /lib/systemd/system/php7.1-fpm.service ]]; then
  sock=php7.1-fpm
else
  sock=php7.0-fpm
fi

for i in NGC SSC PROX FIC; do
  cmd=$(sed -n -e '/'$i'/,/'$i'/ p' /etc/swizzin/scripts/install/nginx.sh)
  eval "$cmd"
done

if [[ ! $hostname == "_" ]]; then
  sed -i "s/server_name _;/server_name $hostname;/g" /etc/nginx/sites-enabled/default
  sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/nginx\/ssl\/${hostname}\/fullchain.pem;/g" /etc/nginx/sites-enabled/default
  sed -i "s/ssl_certificate_key .*/ssl_certificate_key \/etc\/nginx\/ssl\/${hostname}\/key.pem;/g" /etc/nginx/sites-enabled/default
fi

for i in "${locks[@]}"; do
  app=${i}
  if [[ -f /install/.$app.lock ]]; then
    echo "Reinstalling nginx config for $app"
    /usr/local/bin/swizzin/nginx/$app.sh
  fi
done

systemctl reload nginx