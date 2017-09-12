#!/bin/bash
# A script to reset your nginx configs to the latest versions "upgrading" nginx
# Beware, this script *will* overwrite any personal modifications you have made.
# Author: liara

hostname=$(cat /etc/nginx/sites-enabled/default | grep -m1 -i server_name | sed 's/server_name//g' | sed 's/ //'g | sed 's/;//g')

rm -rf /etc/nginx/apps/*
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/conf.d/*
rm -rf /etc/nginx/snippets/{ssl-params,proxy,fancyindex}.conf

for i in NGC SSC PROX FIC; do
  cmd=$(sed -n -e '/'$i'/,/'$i'/ p' /etc/swizzin/scripts/install/nginx.sh)
  eval "$cmd"
done

if [[ ! $hostname == "_" ]]; then
  sed -i "s/ssl_certificate .*/ssl_certificate \/etc\/nginx\/ssl\/${hostname}\/fullchain.pem;/g" /etc/nginx/sites-enabled/default
  sed -i "s/ssl_certificate_key .*/ssl_certificate_key \/etc\/nginx\/ssl\/${hostname}\/key.pem;/g" /etc/nginx/sites-enabled/default
fi

locks=($(find /usr/local/bin/swizzin/nginx -type f -printf "%f\n" | cut -d "." -f 1 | sort -d -r))
for i in "${locks[@]}"; do
  app=${i}
  if [[ -f /install/.$app.lock ]]; then
    echo "Installing nginx config for $app"
    /usr/local/bin/swizzin/nginx/$app.sh
  fi
done

systemctl reload nginx