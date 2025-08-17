#!/bin/bash
# Nginx conf for *Arr
# Flying sausages 2020 / Bakerboy448 2021
# Refactored by B 2022
master=$(_get_master_username)
app_name="whisparr"

if ! WHISPARR_OWNER="$(swizdb get $app_name/owner)"; then
    WHISPARR_OWNER=$(_get_master_username)
else
    WHISPARR_OWNER="$(swizdb get $app_name/owner)"
fi

app_port="6900"
app_sslport="9600"
user="$WHISPARR_OWNER"
app_servicefile="${app_name}.service"
app_configdir="/home/$user/.config/${app_name^}"
app_baseurl="$app_name"
app_branch="nightly"

cat > /etc/nginx/apps/$app_name.conf << WHISPARR
location /$app_baseurl {
  proxy_pass        http://127.0.0.1:$app_port/$app_baseurl;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${master};

  proxy_http_version 1.1;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection \$http_connection;
 }
  # Allow the App API
  location /$app_baseurl/api { auth_request off;
    proxy_pass http://127.0.0.1:$app_port/$app_baseurl/api;
 }
WHISPARR

wasActive=$(systemctl is-active $app_servicefile)

if [[ $wasActive == "active" ]]; then
    echo_log_only "Stopping $app_name"
    systemctl stop "$app_servicefile"
fi
apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" "$app_configdir"/config.xml)

# Set to Debug as this is beta software
# ToDo: Logs back to Info
cat > "$app_configdir"/config.xml << WHISPARR
<Config>
  <LogLevel>debug</LogLevel>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <BindAddress>127.0.0.1</BindAddress>
  <Port>$app_port</Port>
  <SslPort>$app_sslport</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>${apikey}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <UrlBase>$app_baseurl</UrlBase>
  <Branch>$app_branch</Branch>
</Config>
WHISPARR

chown -R "$user":"$user" "$app_configdir"

# Switch app back off if it was dead before; otherwise start it
if [[ $wasActive == "active" ]]; then
    systemctl start "$app_servicefile" -q
fi
