#!/bin/bash
# Nginx conf for autobrr
# ludviglundgren 2021
master=$(_get_master_username)
app_name="autobrr"

app_port="9090"
app_servicefile="${app_name}.service"
app_baseurl="$app_name"

cat > /etc/nginx/apps/$app_name.conf << AUTOBRR
location /$app_baseurl/ {
  proxy_pass http://127.0.0.1:$app_port/;
  include /etc/nginx/snippets/proxy.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${master};
}
AUTOBRR

wasActive=$(systemctl is-active $app_servicefile)

if [[ $wasActive == "active" ]]; then
    echo_log_only "Stopping $app_name"
    systemctl stop "$app_servicefile"
fi

# Switch app back off if it was dead before; otherwise start it
if [[ $wasActive == "active" ]]; then
    systemctl start "$app_servicefile" -q
fi
