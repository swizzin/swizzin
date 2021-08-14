#!/bin/bash
# autobrr nginx conf
# ludviglundgren 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
users=($(_get_user_list))

if [[ ! -f /etc/nginx/apps/autobrr.conf ]]; then

    cat > /etc/nginx/apps/autobrr.conf << 'AUTOBRR'
location /brr {
    return 301 /autobrr/;
}

location /autobrr/ {
    proxy_pass              http://$remote_user.autobrr;
    proxy_http_version      1.1;
    proxy_set_header        X-Forwarded-Host        $http_host;

    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd;

    rewrite ^/autobrr/(.*) /$1 break;
}
AUTOBRR
fi

for user in ${users[@]}; do
    port=$(grep 'port =' /home/${user}/.config/autobrr/config.toml | awk '{ print $3 }')
    cat > /etc/nginx/conf.d/${user}.autobrr.conf << AUTOBRRUC
upstream ${user}.autobrr {
  server 127.0.0.1:${port};
}
AUTOBRRUC
done
