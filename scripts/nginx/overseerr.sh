#!/usr/bin/env bash

cat > /etc/nginx/apps/overseerr.conf << EOF
location ^~ /overseerr {
    set \$app 'overseerr';
    # Remove /overseerr path to pass to the app
    rewrite ^/overseerr/?(.*)\$ /\$1 break;
    proxy_pass http://127.0.0.1:5055;  # NO TRAILING SLASH
    # Redirect location headers
    proxy_redirect ^ /\$app;
    proxy_redirect /setup /\$app/setup;
    proxy_redirect /login /\$app/login;
    # Sub filters to replace hardcoded paths
    proxy_set_header Accept-Encoding "";
    sub_filter_once off;
    sub_filter_types *;
    sub_filter 'href="/"' 'href="/\$app"';
    sub_filter 'href="/login"' 'href="/\$app/login"';
    sub_filter 'href:"/"' 'href:"/\$app"';
    sub_filter '/_next' '/\$app/_next';
    sub_filter '/api/v1' '/\$app/api/v1';
    sub_filter '/login/plex/loading' '/\$app/login/plex/loading';
    sub_filter '/images/' '/\$app/images/';
    sub_filter '/android-' '/\$app/android-';
    sub_filter '/apple-' '/\$app/apple-';
    sub_filter '/favicon' '/\$app/favicon';
    sub_filter '/logo.png' '/\$app/logo.png';
    sub_filter '/site.webmanifest' '/\$app/site.webmanifest';
}
EOF

cat > /opt/overseerr/env.conf << EOF

# specify on which interface to listen, by default overseerr listens on all interfaces
HOST=127.0.0.1
EOF

systemctl try-restart overseerr
