#!/bin/bash
# Brett 2021
function mylar_ngx() {
    if [[ -f /install/.nginx.lock ]]; then
        cat > /etc/nginx/apps/${app_name}.conf << NGX
location ^~ /${app_name} {
    include /etc/nginx/snippets/proxy.conf;
    proxy_pass http://127.0.0.1:${app_port};
}
NGX
        nginx -s reload >> $log 2>&1 || echo_error "Something went wrong with nginx. Please run nginx -t"
        echo_info "Mylar is now up and running on https://yourdomain.tld/mylar"
    fi
    systemctl restart -q ${app_servicefile}
}
