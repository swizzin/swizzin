#!/bin/bash
# Nginx conf for Sonarr v3
# Flying sausages 2020
master=$(cut -d: -f1 < /root/.master.info)

cat > /etc/nginx/apps/sonarr.conf << SONARR
location /sonarr {
  proxy_pass        http://127.0.0.1:8989/sonarr;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${master};
}
SONARR

isactive=$(systemctl is-active sonarr)

if [[ $isactive == "active" ]]; then
    systemctl stop sonarr
fi
user=$(grep User= /etc/systemd/system/sonarr.service | cut -d= -f2)
#shellcheck disable=SC2154
echo_log_only "Sonarr user detected as $user"
apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"$user"/.config/Sonarr/config.xml)
echo_log_only "API Key  = $apikey"

cat > /home/"$user"/.config/Sonarr/config.xml << SONN
<Config>
  <LogLevel>info</LogLevel>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <Branch>main</Branch>
  <BindAddress>127.0.0.1</BindAddress>
  <Port>8989</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>${apikey}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <SslCertHash></SslCertHash>
  <UrlBase>sonarr</UrlBase>
</Config>
SONN

if [[ -f /install/.rutorrent.lock ]]; then
    sqlite3 /home/"$user"/.config/Sonarr/sonarr.db "INSERT or REPLACE INTO Config VALUES('6', 'certificatevalidation', 'DisabledForLocalAddresses');"
fi

chown -R "$user":"$user" /home/"$user"/.config/Sonarr

if [[ $isactive == "active" ]]; then
    systemctl start sonarr
fi
