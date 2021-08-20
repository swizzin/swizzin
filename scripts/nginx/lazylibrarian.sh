#!/bin/bash
# LazyLibrarian nginx script for swizzin
# Author: Aethaeran

##########################################################################
# Import Sources
##########################################################################

. /etc/swizzin/sources/functions/utils

##########################################################################
# Variables
##########################################################################

app_name=lazylibrarian

##########################################################################
# Main
##########################################################################

# TODO: Simple logic to verify this needs creating.

cat > "/etc/nginx/apps/$app_name.conf" << 'EOF'
location /lazylibrarian {
        proxy_bind              $server_addr;
        proxy_pass              http://127.0.0.1:5299;
        proxy_set_header        Host            $http_host;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Scheme        $scheme;
        proxy_set_header        X-Script-Name   /lazylibrarian;  # IMPORTANT: path has NO trailing slash
}
EOF
