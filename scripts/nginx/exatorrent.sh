#!/bin/bash
cat > /etc/nginx/apps/transmission.conf << TCONF

location /exatorrent/ {
    proxy_set_header        X-Real-IP       \$remote_addr;
    proxy_set_header        X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header        Host            \$http_host;
    proxy_set_header        X-NginX-Proxy   true;
    proxy_set_header        Connection      "";
    add_header              Front-End-Https on;
    proxy_http_version      1.1;
    proxy_pass_header       X-Transmission-Session-Id;
    auth_basic              "What's the password?";
    auth_basic_user_file    /etc/htpasswd;
    proxy_pass              http://\$remote_user.exatorrent;
}
TCONF

for user in $(_get_user_list); do
    # socket=/var/run/$user/exatorrent.sock

    port=$(jq -r '.ListenPort' /home/$user/exatorrent/config/clientconfig.json)
    cat > /etc/nginx/conf.d/"${user}".exatorrent.conf << TDCONF
upstream ${user}.exatorrent {
    server 127.0.0.1:${port};
}
TDCONF
done
