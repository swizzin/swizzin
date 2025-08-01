#!/bin/bash
# netronome nginx conf
# soup 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
users=($(_get_user_list))

cat > /etc/nginx/apps/netronome.conf << 'netronome'
location /netronome/ {
    proxy_pass              http://$remote_user.netronome;
    proxy_http_version      1.1;
    proxy_set_header        X-Forwarded-Host        $http_host;

    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd;
}
netronome

for user in ${users[@]}; do
    port=$(grep 'port =' /home/${user}/.config/netronome/config.toml | awk '{ print $3 }')
    cat > /etc/nginx/conf.d/${user}.netronome.conf << netronomeUC
upstream ${user}.netronome {
  server 127.0.0.1:${port};
}
netronomeUC

    # change listening addr to 127.0.0.1
    sed -i 's|host = "0.0.0.0"|host = "127.0.0.1"|g' "/home/${user}/.config/netronome/config.toml"

    # Restart netronome for all user after changing port
    echo_log_only "Restarting netronome for ${user}"
    systemctl try-restart netronome@${user}

done
