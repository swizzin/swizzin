#!/bin/bash
#
ex_ip="$(ip -br a | sed -n 2p | awk '{ print $3 }' | cut -f1 -d'/')"
mkdir -p "/etc/nginx/apps/authelia"
sed 's|include /etc/nginx/apps/\*;|include /etc/nginx/apps/*.conf;|g' -i /etc/nginx/sites-enabled/default

cat > "/etc/nginx/apps/authelia.conf" << AUTHELIA_NGINX_1
location / {
    set \$upstream_authelia http://127.0.0.1:9091;
    proxy_pass \$upstream_authelia;
    include /etc/nginx/apps/authelia/authelia_proxy.conf;
}

# Virtual endpoint created by nginx to forward auth requests.
location /authelia {
    internal;
    set \$upstream_authelia http://127.0.0.1:9091/api/verify;
    proxy_pass_request_body off;
    proxy_pass \$upstream_authelia;
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
    proxy_set_header X-Forwarded-For \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Host \$http_host;
    proxy_set_header X-Forwarded-Uri \$request_uri;
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
AUTHELIA_NGINX_1

cat > "/etc/nginx/apps/authelia/authelia_auth.conf" << AUTHELIA_NGINX_2
# Basic Authelia Config
# Send a subsequent request to Authelia to verify if the user is authenticated
# and has the right permissions to access the resource.
auth_request /authelia;
# Set the \$(target_url) variable based on the request. It will be used to build the portal
# URL with the correct redirection parameter.
auth_request_set \$target_url \$scheme://\$http_host\$request_uri;
# Set the X-Forwarded-User and X-Forwarded-Groups with the headers
# returned by Authelia for the backends which can consume them.
# This is not safe, as the backend must make sure that they come from the
# proxy. In the future, it's gonna be safe to just use OAuth.
auth_request_set \$user \$upstream_http_remote_user;
auth_request_set \$groups \$upstream_http_remote_groups;
proxy_set_header Remote-User \$user;
proxy_set_header Remote-Groups \$groups;
# If Authelia returns 401, then nginx redirects the user to the login portal.
# If it returns 200, then the request pass through to the backend.
# For other type of errors, nginx will handle them as usual.
error_page 401 =302 https://${ex_ip}/?rd=\$target_url;
AUTHELIA_NGINX_2

cat > "/etc/nginx/apps/authelia/authelia_proxy.conf" << AUTHELIA_NGINX_3
client_body_buffer_size 128k;

#Timeout if the real server is dead
proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;

# Advanced Proxy Config
send_timeout 5m;
# proxy_read_timeout 360;
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
# proxy_http_version 1.1;
proxy_set_header Connection "";
proxy_cache_bypass \$cookie_session;
proxy_no_cache \$cookie_session;
proxy_buffers 64 256k;

# If behind reverse proxy, forwards the correct IP
set_real_ip_from 10.0.0.0/8;
set_real_ip_from 172.0.0.0/8;
set_real_ip_from 192.168.0.0/16;
set_real_ip_from fc00::/7;
real_ip_header X-Forwarded-For;
real_ip_recursive on;
AUTHELIA_NGINX_3
