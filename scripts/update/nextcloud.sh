#!/bin/bash
# Nextcloud updates

if [[ -f /install/.nextcloud.lock ]]; then
    if ! grep -q 'set $path_info' /etc/nginx/apps/nextcloud.conf; then
        echo_progress_start "Updating Nextcloud nginx config"
        . /etc/swizzin/sources/functions/php
        phpversion=$(php_service_version)
        sock="php${phpversion}-fpm"
        cat > /etc/nginx/apps/nextcloud.conf << EOF
# The following 2 rules are only needed for the user_webfinger app.
# Uncomment it if you're planning to use this app.
#rewrite ^/.well-known/host-meta /nextcloud/public.php?service=host-meta last;
#rewrite ^/.well-known/host-meta.json /nextcloud/public.php?service=host-meta-json last;

# The following rule is only needed for the Social app.
# Uncomment it if you're planning to use this app.
#rewrite ^/.well-known/webfinger /nextcloud/public.php?service=webfinger last;

location = /.well-known/carddav {
  return 301 \$scheme://\$host:\$server_port/nextcloud/remote.php/dav;
}
location = /.well-known/caldav {
  return 301 \$scheme://\$host:\$server_port/nextcloud/remote.php/dav;
}

location /.well-known/acme-challenge { }

location ^~ /nextcloud {

    # set max upload size
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    # Enable gzip but do not remove ETag headers
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    # Uncomment if your server is build with the ngx_pagespeed module
    # This module is currently not supported.
    #pagespeed off;

    location /nextcloud {
        rewrite ^ /nextcloud/index.php;
    }

    location ~ ^\/nextcloud\/(?:build|tests|config|lib|3rdparty|templates|data)\/ {
        deny all;
    }
    location ~ ^\/nextcloud\/(?:\.|autotest|occ|issue|indie|db_|console) {
        deny all;
    }

    location ~ ^\/nextcloud\/(?:index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+)\.php(?:\$|\/) {
        fastcgi_split_path_info ^(.+?\.php)(\/.*|)\$;
        set \$path_info \$fastcgi_path_info;
        try_files \$fastcgi_script_name =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$path_info;
        fastcgi_param HTTPS on;
        # Avoid sending the security headers twice
        fastcgi_param modHeadersAvailable true;
        # Enable pretty urls
        fastcgi_param front_controller_active true;
        fastcgi_pass unix:/run/php/$sock.sock;
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
    }

    location ~ ^\/nextcloud\/(?:updater|oc[ms]-provider)(?:\$|\/) {
        try_files \$uri/ =404;
        index index.php;
    }

    # Adding the cache control header for js, css and map files
    # Make sure it is BELOW the PHP block
    location ~ ^\/nextcloud\/.+[^\/]\.(?:css|js|woff2?|svg|gif|map)\$ {
        try_files \$uri /nextcloud/index.php\$request_uri;
        add_header Cache-Control "public, max-age=15778463";
        # Add headers to serve security related headers  (It is intended
        # to have those duplicated to the ones above)
        # Before enabling Strict-Transport-Security headers please read
        # into this topic first.
        #add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;
        #
        # WARNING: Only add the preload option once you read about
        # the consequences in https://hstspreload.org/. This option
        # will add the domain to a hardcoded list that is shipped
        # in all major browsers and getting removed from this list
        # could take several months.
        add_header Referrer-Policy "no-referrer" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Download-Options "noopen" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Permitted-Cross-Domain-Policies "none" always;
        add_header X-Robots-Tag "none" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # Optional: Don't log access to assets
        access_log off;
    }

    location ~ ^\/nextcloud\/.+[^\/]\.(?:png|html|ttf|ico|jpg|jpeg|bcmap)\$ {
        try_files \$uri /nextcloud/index.php\$request_uri;
        # Optional: Don't log access to other assets
        access_log off;
    }
}
EOF
        systemctl reload nginx
        echo_progress_done
    fi
fi
