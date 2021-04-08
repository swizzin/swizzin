#!/bin/bash
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/app_port
. /etc/swizzin/sources/functions/app_port
#
app_proxy_port="$(_get_app_port "$(basename -- "$0" \.sh)")" # Get our app port using the install script name as the app name
#
if [[ "$(systemctl is-active authelia)" == "active" ]]; then
    systemctl -q stop authelia &>> "${log}"
fi
# Create an /etc/nginx/apps subdirectory we need
mkdir -p "/etc/nginx/apps/authelia"

cat > "/etc/nginx/apps/authelia.conf" << AUTHELIA_CONF_NGINX
set \$upstream_authelia http://127.0.0.1:${app_proxy_port}; # set the resued upstream proxypass url
# include /etc/nginx/apps/authelia/authelia_portal.conf; # Include the portal conf
include /etc/nginx/apps/authelia/authelia_api.conf; # Include the api conf
AUTHELIA_CONF_NGINX

cat > "/etc/nginx/apps/authelia/authelia_portal.conf" << AUTHELIA_PORTAL_NGINX
location /login {
    proxy_pass \$upstream_authelia;
    include /etc/nginx/apps/authelia/authelia_proxy.conf;
}
AUTHELIA_PORTAL_NGINX

cat > "/etc/nginx/apps/authelia/authelia_api.conf" << AUTHELIA_API_NGINX
# set \$auth_type "/login/api/verify"; # normal auth
set \$auth_type "/login/api/verify?auth=basic"; # basic auth

# Virtual endpoint created by nginx to forward auth requests.
location /login/api/verify {
    internal;
    proxy_pass_request_body off;
    proxy_pass \$upstream_authelia\$auth_type;
    proxy_set_header Content-Length "";

    # Timeout if the real server is dead
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

    # [REQUIRED] Needed by Authelia to check authorizations of the resource.
    # Provide either X-Original-URL and X-Forwarded-Proto or
    # X-Forwarded-Proto, X-Forwarded-Host and X-Forwarded-Uri or both.
    # Those headers will be used by Authelia to deduce the target url of the user.
    # Basic Proxy Config
    client_body_buffer_size 128k;
    proxy_set_header Host \$host;
    proxy_set_header X-Original-URL \$scheme://\$http_host\$request_uri;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Method \$request_method;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Host \$http_host;
    proxy_set_header X-Forwarded-Uri \$request_uri;
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_set_header X-Forwarded-Ssl on;
    proxy_redirect  http://  \$scheme://;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_cache_bypass \$cookie_session;
    proxy_no_cache \$cookie_session;
    proxy_buffers 4 32k;

    # Advanced Proxy Config
    send_timeout 5m;
    proxy_read_timeout 240;
    proxy_send_timeout 240;
    proxy_connect_timeout 240;
}
AUTHELIA_API_NGINX
# Create the auth redicrect conf
cat > "/etc/nginx/apps/authelia/authelia_auth.conf" << AUTHELIA_AUTH_NGINX
# Basic Authelia Config
# Send a subsequent request to Authelia to verify if the user is authenticated
# and has the right permissions to access the resource.
auth_request /login/api/verify;
# Set the \$(target_url) variable based on the request. It will be used to build the portal
# URL with the correct redirection parameter.
auth_request_set \$target_url \$scheme://\$http_host\$request_uri;
# Set the X-Forwarded-User and X-Forwarded-Groups with the headers
# returned by Authelia for the backends which can consume them.
# This is not safe, as the backend must make sure that they come from the
# proxy. In the future, it's gonna be safe to just use OAuth.
auth_request_set \$user \$upstream_http_remote_user;
auth_request_set \$groups \$upstream_http_remote_groups;
auth_request_set \$name \$upstream_http_remote_name;
auth_request_set \$email \$upstream_http_remote_email;
proxy_set_header Remote-User \$user;
proxy_set_header Remote-Groups \$groups;
proxy_set_header Remote-Name \$name;
proxy_set_header Remote-Email \$email;
# If Authelia returns 401, then nginx redirects the user to the login portal.
# If it returns 200, then the request pass through to the backend.
# For other type of errors, nginx will handle them as usual.
error_page 401 =302 https://\$http_host; # redirect to / so panel can handle auth
AUTHELIA_AUTH_NGINX
# Create the proxy settings conf
cat > "/etc/nginx/apps/authelia/authelia_proxy.conf" << AUTHELIA_PROXY_NGINX
client_body_buffer_size 128k;

#Timeout if the real server is dead
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

# Advanced Proxy Config
send_timeout 5m;
proxy_read_timeout 360;
proxy_send_timeout 360;
proxy_connect_timeout 360;

# Basic Proxy Config
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
proxy_set_header X-Forwarded-Host \$http_host;
proxy_set_header X-Forwarded-Uri \$request_uri;
proxy_set_header X-Forwarded-Ssl on;
proxy_redirect  http://  \$scheme://;
proxy_http_version 1.1;
proxy_set_header Connection "";
proxy_cache_bypass \$cookie_session;
proxy_no_cache \$cookie_session;
proxy_buffers 64 256k;

# If behind reverse proxy, forwards the correct IP
set_real_ip_from 10.0.0.0/8;
set_real_ip_from 172.16.0.0/12;
set_real_ip_from 192.168.0.0/16;
set_real_ip_from fc00::/7;
real_ip_header X-Forwarded-For;
real_ip_recursive on;
AUTHELIA_PROXY_NGINX
#
if [[ ! "${1}" =~ (install|upgrade) ]]; then
    systemctl -q start authelia &>> "${log}"
fi
