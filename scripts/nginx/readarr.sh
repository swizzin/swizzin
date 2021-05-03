#!/bin/bash
# Nginx conf for Radarr v3
# Flying sausages 2020
# Refactored by Bakerboy448 2021
master=$(cut -d: -f1 < /root/.master.info)
app_name="readarr"
if ! READARR_OWNER="$(swizdb get $app_name/owner)"; then
    READARR_OWNER=$(_get_master_username)
else
    READARR_OWNER="$(swizdb get $app_name/owner)"
fi
app_port="8787"
user="$READARR_OWNER"
app_servicename="${app_name}"
app_configdir="/home/$user/.config/${app_name^}"
app_baseurl=$app_name

cat > /etc/nginx/apps/$app_name.conf << READARR
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
}
READARR

isactive=$(systemctl is-active $app_servicename)

if [[ $isactive == "active" ]]; then
    echo_log_only "Stopping $app_servicename"
    systemctl stop $app_servicename
fi
user=$(grep User /etc/systemd/system/$app_servicename.service | cut -d= -f2)
echo_log_only "${app_name^} user detected as $user"
apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" "$app_configdir"/config.xml)
echo_log_only "Apikey = $apikey" >> "$log"

# Set to Debug as this is alpha software
cat > "$app_configdir"/config.xml << READARR
<Config>
  <LogLevel>debug</LogLevel>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <BindAddress>127.0.0.1</BindAddress>
  <Port>$app_port</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>${apikey}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <UrlBase>$app_baseurl</UrlBase>
</Config>
READARR

chown -R "$user":"$user" "$app_configdir"

systemctl start $app_servicename -q # Switch app on regardless whether it was off before or not as we need to have it online to trigger this cahnge
if ! timeout 15 bash -c -- "while ! curl -fL \"http://127.0.0.1:$app_port/api/v1/system/status?apiKey=${apikey}\" >> \"$log\" 2>&1; do sleep 5; done"; then
    echo_error "${app_name^} API did not respond as expected. Please make sure ${app_name^} is up to date and running."
    exit 1
else
    urlbase="$(curl -sL "http://127.0.0.1:${app_port}/api/v1/config/host?apikey=${apikey}" | jq '.urlBase' | cut -d '"' -f 2)"
    echo_log_only "${app_name^} API tested and reachable"
fi

payload=$(curl -sL "http://127.0.0.1:${app_port}/api/v1/config/host?apikey=${apikey}" | jq ".certificateValidation = \"disabledForLocalAddresses\"")
echo_log_only "Payload = \n${payload}"
echo_log_only "Return from ${app_name^} after PUT ="
curl -s "http://127.0.0.1:$app_port/$urlbase/api/v1/config/host?apikey=${apikey}" -X PUT -H 'Accept: application/json, text/javascript, */*; q=0.01' --compressed -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data-raw "${payload}" >> "$log"

# Switch app back off if it was dead before
if [[ $isactive != "active" ]]; then
    systemctl stop app_servicename
fi
