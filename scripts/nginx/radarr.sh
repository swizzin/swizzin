#!/bin/bash
# *Arr NGINX config Installer for Radarr
# Refactored from existing files by FlyingSausages and others
# Bakerboy448 2021 for Swizzin

#ToDo this should all be wrote to SwizDB; Need to ensure swizdb is updated for existing installs
app_name="radarr"
app_port="$(swizdb get "$app_name/port")"
app_apiversion="$(swizdb get "$app_name/apiversion")"
app_nginxname="$(swizdb get "$app_name/nginxname")"
app_urlbase="$(swizdb get "$app_name/urlbase")"
app_user="$(swizdb get $app_name/owner)"
app_configdir="$(swizdb get $app_name/configdir)"
master=$(cut -d: -f1 < /root/.master.info)

cat > /etc/nginx/apps/"$app_nginxname".conf << RADARR
location /$app_name {
  proxy_pass        http://127.0.0.1:$app_port/$app_urlbase;
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
RADARR

isactive=$(systemctl is-active $app_name)

if [[ $isactive == "active" ]]; then
    echo_log_only "Stopping $app_name"
    systemctl stop $app_name
fi
echo_log_only "${app_name^} user detected as $app_user"
apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" "$app_configdir"/config.xml)
echo_log_only "Apikey = $apikey" >> "$log"

cat > "$app_configdir"/config.xml << RADARR
<Config>
  <LogLevel>info</LogLevel>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <BindAddress>127.0.0.1</BindAddress>
  <Port>$app_port</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>${apikey}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <UrlBase>$app_urlbase</UrlBase>
</Config>
RADARR

chown -R "$app_user":"$app_user" "$app_configdir"

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
systemctl start $app_name -q # Switch radarr on regardless whether it was off before or not as we need to have it online to trigger this cahnge
if ! timeout 15 bash -c -- "while ! curl -fL \"http://127.0.0.1:$app_port/api/$app_apiversion/system/status?apiKey=${apikey}\" >> \"$log\" 2>&1; do sleep 5; done"; then
    echo_error "${app_name^} API did not respond as expected. Please make sure ${app_name^} is running."
    exit 1
else
    app_urlbase_queried="$(curl -sL "http://127.0.0.1:$app_port/api/$app_apiversion/config/host?apikey=${apikey}" | jq '.urlBase' | cut -d '"' -f 2)"
    if [ "$app_urlbase_queried" = "$app_urlbase" ]; then
        echo_log_only "${app_name^} API tested and reachable"
    else
        echo_error "${app_name^} API did not respond as expected. Queried urlbase $app_urlbase_queried did not match expected $app_urlbase"
    fi
fi

payload=$(curl -sL "http://127.0.0.1:$app_port/api/$app_apiversion/config/host?apikey=${apikey}" | jq ".certificateValidation = \"disabledForLocalAddresses\"")
echo_log_only "Payload = \n${payload}"
echo_log_only "Return from ${app_name^} after PUT ="
curl -s "http://127.0.0.1:$app_port${app_urlbase}/api/$app_apiversion/config/host?apikey=${apikey}" -X PUT -H 'Accept: application/json, text/javascript, */*; q=0.01' --compressed -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data-raw "${payload}" >> "$log"

# Switch $app_name back off if it was dead before
if [[ "$isactive" != "active" ]]; then
    systemctl stop "$app_name"
fi
