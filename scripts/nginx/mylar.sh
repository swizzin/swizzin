#!/bin/bash
# Brett 2021
function mylar_ngx() {
    if [[ -f /install/.nginx.lock ]]; then
        cat > /etc/nginx/apps/${app_name}.conf << NGX
location ^~ /${app_name} {
    # enable the next two lines for http auth
    #auth_basic "Restricted";
    #auth_basic_user_file /etc/htpasswd.d/$user;

    include /etc/nginx/snippets/proxy.conf;
    proxy_pass http://127.0.0.1:${app_port};
}
NGX
        sleep 10
        sed -i "s|http_port = 8090|http_port = ${app_port}|g" $app_configfile
        sed -i "s|http_host = 0.0.0.0|http_host = 127.0.0.1|g" $app_configfile
        sed -i "s|http_root = /|http_root = /mylar|g" $app_configfile
        nginx -s reload >> $log 2>&1 || echo_error "Something went wrong with nginx. Please run nginx -t"
        systemctl restart -q ${app_servicefile}
        echo_info "Mylar is now up and running on https://yourdomain.tld:${app_port}/mylar"
    else
        echo_info "Mylar is now up and running on ${app_port}"
    fi
}
