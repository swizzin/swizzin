#!/bin/bash
# qui nginx conf
# soup 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
users=($(_get_user_list))

cat > /etc/nginx/apps/qui.conf << 'qui'
# Redirect /qui to /qui/ for proper SPA routing
location = /qui {
    return 301 /qui/;
}

location /qui/ {
    proxy_pass              http://$remote_user.qui;
    proxy_http_version      1.1;
    proxy_set_header        Host $host;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_set_header        X-Forwarded-Host $http_host;

    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd;
}
qui

for user in ${users[@]}; do
    port=$(grep 'port =' /home/${user}/.config/qui/config.toml | awk '{ print $3 }')
    cat > /etc/nginx/conf.d/${user}.qui.conf << quiUC
upstream ${user}.qui {
  server 127.0.0.1:${port};
}
quiUC

    # change listening addr to 127.0.0.1
    sed -i 's|host = "0.0.0.0"|host = "127.0.0.1"|g' "/home/${user}/.config/qui/config.toml"

    # Restart qui for all user after changing port
    echo_log_only "Restarting qui for ${user}"
    systemctl try-restart qui@${user}

done