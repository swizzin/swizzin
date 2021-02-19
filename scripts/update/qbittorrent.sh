#!/bin/bash

if [[ -f /install/.qbittorrent.lock ]]; then
    #Check systemd service for updates
    type=simple
    if [[ $(systemctl --version | awk 'NR==1 {print $2}') -ge 240 ]]; then
        unittype=exec
    fi
    if ! grep -q Type=$unittype /etc/systemd/system/qbittorrent@.service; then
        sed -i "s/Type=.*/Type=$unittype/g" /etc/systemd/system/qbittorrent@.service
        reloadsys=true
    fi
    if grep -q "qbittorrent-nox -d" /etc/systemd/system/qbittorrent@.service; then
        sed -i 's|/usr/bin/qbittorrent-nox -d|/usr/bin/qbittorrent-nox|g' /etc/systemd/system/qbittorrent@.service
        reloadsys=true
    fi
    if [[ $reloadsys == true ]]; then
        systemctl daemon-reload
        echo_info "qBittorrent systemd services have been updated. Please restart qBittorrent services at your convenience."
    fi
    if [[ -f /etc/nginx/apps/qbittorrent.conf ]]; then
        if ! grep -q "proxy_connect_timeout" /etc/nginx/apps/qbittorrent.conf; then
            echo_log_only "Adding timeouts and optimizations to qbit nginx conf"
            cat > /etc/nginx/apps/qbittorrent.conf << EOF
location /qbt {
    return 301 /qbittorrent/;
}
location /qbittorrent/ {
    proxy_pass              http://$remote_user.qbittorrent;
    proxy_http_version      1.1;
    proxy_set_header        X-Forwarded-Host        $http_host;
    http2_push_preload on; # Enable http2 push
    auth_basic "What's the password?";

    auth_basic_user_file /etc/htpasswd;
    rewrite ^/qbittorrent/(.*) /$1 break;

    # Timeouts
    proxy_connect_timeout  2000ms;
    proxy_send_timeout     2000ms;
    proxy_read_timeout     2000ms;

    # Change buffer sizes for better performance on large queues
    client_max_body_size 24M;
    client_body_buffer_size 128k;    
    fastcgi_buffers 8 16k;
    fastcgi_buffer_size 32k;
    
    # The following directives effectively nullify Cross-site request forgery (CSRF)
    # protection mechanism in qBittorrent, only use them when you encountered connection problems.
    # You should consider disable "Enable Cross-site request forgery (CSRF) protection"
    # setting in qBittorrent instead of using these directives to tamper the headers.
    # The setting is located under "Options -> WebUI tab" in qBittorrent since v4.1.2.
    #proxy_hide_header       Referer;
    #proxy_hide_header       Origin;
    #proxy_set_header        Referer                 '';
    #proxy_set_header        Origin                  '';

    # Not needed since qBittorrent v4.1.0
    #add_header              X-Frame-Options         "SAMEORIGIN";
}

EOF
            systemctl nginx reload
        fi
    fi
fi
