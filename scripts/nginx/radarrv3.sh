#!/bin/bash
# Nginx conf for Sonarr v3
# Flying sausages 2020
master=$(cut -d: -f1 < /root/.master.info)

cat > /etc/nginx/apps/radarrv3.conf <<RADARR
location /radarr {
  proxy_pass        http://127.0.0.1:7878/radarr;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${master};
}
RADARR

isactive=$(systemctl is-active radarr)

if [[ $isactive == "active" ]]; then
  systemctl stop radarr
fi
user=$(grep User /lib/systemd/system/radarr.service | cut -d= -f2)
#shellcheck disable=SC2154
echo "Sonarr user detected as $user" >> "$log"
apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"$user"/.config/Radarr/config.xml)
echo "API Key  = $apikey" >> "$log"
#TODO cahnge Branch whenever that becomes relevant
cat > /home/"$user"/.config/Radarr/config.xml <<SONN
<Config>
  <LogLevel>info</LogLevel>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <Branch>nightly</Branch>
  <BindAddress>127.0.0.1</BindAddress>
  <Port>7878</Port>
  <SslPort>8787</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>${apikey}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <UrlBase>radarr</UrlBase>
</Config>
SONN
chown -R "$user":"$user" /home/"$user"/.config/Radarr

# chown -R ${master}: /home/${master}/.config/NzbDrone/
if [[ $isactive == "active" ]]; then
  systemctl start radarr
fi