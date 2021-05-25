#!/bin/bash
# Nginx conf for *Arr
# Flying sausages 2020
# Refactored by Bakerboy448 2021
master=$(cut -d: -f1 < /root/.master.info)
app_name="prowlarr"
if ! PROWLARR_OWNER="$(swizdb get $app_name/owner)"; then
    PROWLARR_OWNER=$(_get_master_username)
else
    PROWLARR_OWNER="$(swizdb get $app_name/owner)"
fi
app_port="9696"
user="$PROWLARR_OWNER"
app_servicefile="${app_name}".service
app_configdir="/home/$user/.config/${app_name^}"
app_baseurl=$app_name

cat > /etc/nginx/apps/$app_name.conf << PROWLARR
location /$app_name {
  proxy_pass        http://127.0.0.1:$app_port/;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${master};

  proxy_http_version 1.1;
  proxy_set_header Upgrade \$http_upgrade;
  proxy_set_header Connection \$http_connection;
  # Allow the App API
  location /$app_baseurl/api { auth_request off;
    proxy_pass http://127.0.0.1:$app_port/$app_baseurl/api;
  }
    # Allow Content
  location /$app_baseurl/Content { auth_request off;
    proxy_pass http://127.0.0.1:$app_port/$app_baseurl/Content;
  }
  # Allow Indexers
  location ~ /prowlarr/[0-9]+/api { auth_request off
  proxy_pass       http://127.0.0.1:9696/prowlarr/$1/api;
}

}
PROWLARR

isactive=$(systemctl is-active $app_servicefile)

if [[ $isactive == "active" ]]; then
    echo_log_only "Stopping $app_servicefile"
    systemctl stop $app_servicename
fi
user=$(grep User /etc/systemd/system/$app_servicefile" | cut -d= -f2)
echo_log_only "${app_name^} user detected as $user"
apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" "$app_configdir"/config.xml)
echo_log_only "Apikey = $apikey" >> "$log"

# Set to Debug as this is alpha software
cat > "$app_configdir"/config.xml << PROWLARR
<Config>
  <LogLevel>debug</LogLevel>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <BindAddress>127.0.0.1</BindAddress>
  <Port>$app_port</Port>
  <SslPort>9897</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>${apikey}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <UrlBase>$app_baseurl</UrlBase>
</Config>
PROWLARR

chown -R "$user":"$user" "$app_configdir"

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
systemctl start $app_servicefile" -q # Switch app on regardless whether it was off before or not as we need to have it online to trigger this cahnge
if ! timeout 15 bash -c -- "while ! curl -fL \"http://127.0.0.1:$app_port/api/v1/system/status?apiKey=${apikey}\" >> \"$log\" 2>&1; do sleep 5; done"; then
    echo_error "${app_name^} API did not respond as expected. Please make sure ${app_name^} is up to date and running."
    exit 1
else
    urlbase="$(curl -sL "http://127.0.0.1:${app_port}/api/v1/config/host?apikey=${apikey}" | jq '.urlBase' | cut -d '"' -f 2)"
    echo_log_only "${app_name^} API tested and reachable"
fi

payload=$(curl -sL "http://127.0.0.1:${app_port}/api/v1/config/host?apikey=${apikey}" | jq ".certificateValidation = \"disabledForLocalAddresses\"")
echo_log_only "Payload = \n${payload}"

# Switch app back off if it was dead before
if [[ $isactive != "active" ]]; then
    systemctl stop $app_servicefile" -q
fi
