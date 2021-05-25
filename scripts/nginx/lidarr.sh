#!/bin/bash
# Nginx conf for *arr
# Flying sausages 2020
# Refactored by Bakerboy448 2021
master=$(cut -d: -f1 < /root/.master.info)
app_name="lidarr"
if ! LIDARR_OWNER="$(swizdb get $app_name/owner)"; then
    LIDARR_OWNER=$(_get_master_username)
else
    LIDARR_OWNER="$(swizdb get $app_name/owner)"
fi
app_port="8686"
user="$LIDARR_OWNER"
app_servicename="${app_name}"
app_configdir="/home/$user/.config/${app_name^}"
app_baseurl=$app_name

cat > /etc/nginx/apps/$app_name.conf << LIDARR
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
  # Allow the ${app_name^} API
  location /$app_baseurl/api { auth_request off;
        proxy_pass http://127.0.0.1:$app_port/$app_baseurl/api;
  }
    # Allow the ${app_name^} Content
  location /$app_baseurl/Content { auth_request off;
        proxy_pass http://127.0.0.1:$app_port/$app_baseurl/Content;
  }
}
LIDARR

isactive=$(systemctl is-active $app_servicename)

if [[ $isactive == "active" ]]; then
    echo_log_only "Stopping $app_servicename"
    systemctl stop $app_servicename
fi
user=$(grep User /etc/systemd/system/$app_servicename.service | cut -d= -f2)
echo_log_only "${app_name^} user detected as $user"
apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" "$app_configdir"/config.xml)
echo_log_only "Apikey = $apikey" >> "$log"

cat > "$app_configdir"/config.xml << LIDARR
<Config>
  <LogLevel>info</LogLevel>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <BindAddress>127.0.0.1</BindAddress>
  <Port>$app_port</Port>
  <SslPort>9899</SslPort>
  <EnableSsl>False</EnableSsl>
  <LaunchBrowser>False</LaunchBrowser>
  <ApiKey>${apikey}</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <UrlBase>$app_baseurl</UrlBase>
</Config>
LIDARR

chown -R "$user":"$user" "$app_configdir"

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
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

# Switch app back off if it was dead before
if [[ $isactive != "active" ]]; then
    systemctl stop $app_servicename
fi
