#!/bin/bash
# shinkro nginx conf
# 2025 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
readarray -t users < <(_get_user_list)

cat > /etc/nginx/apps/shinkro.conf << 'SHINKRO'
location /shinkro/ {
    proxy_pass              http://$remote_user.shinkro;
    proxy_set_header        Host                    $host;
    proxy_set_header        X-Forwarded-For         $proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Host        $host;
    proxy_set_header        X-Forwarded-Proto       $scheme;
    proxy_set_header        Upgrade                 $http_upgrade;
    proxy_set_header        Connection              $http_connection;

    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd;
}
SHINKRO

for user in "${users[@]}"; do
    port=$(grep '^Port =' "/home/${user}/.config/shinkro/config.toml" | awk '{ print $3 }')
    cat > "/etc/nginx/conf.d/${user}.shinkro.conf" << SHINKROUC
upstream ${user}.shinkro {
  server 127.0.0.1:${port};
}
SHINKROUC

    # change listening addr to 127.0.0.1
    sed -i 's|Host = "0.0.0.0"|Host = "127.0.0.1"|g' "/home/${user}/.config/shinkro/config.toml"

    # Restart shinkro for all user after changing port
    echo_log_only "Restarting shinkro for ${user}"
    systemctl try-restart "shinkro@${user}"

done
