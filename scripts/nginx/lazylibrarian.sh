#!/bin/bash
# LazyLibrarian nginx script for swizzin
# Author: Aethaeran

cat > "/etc/nginx/apps/$app_name.conf" <<NGINXCONF
location /lazylibrarian {
        proxy_bind              $server_addr;
        proxy_pass              http://127.0.0.1:5299;
        proxy_set_header        Host            $http_host;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Scheme        $scheme;
        proxy_set_header        X-Script-Name   /lazylibrarian;  # IMPORTANT: path has NO trailing slash
}
NGINXCONF

# TODO: Verify if "Web Root" needs to be added to LazyLib config
