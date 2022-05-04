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
    #End systemd service updates
    #Check for proxy_cookie_path in nginx to prevent writing cookies to /
    if [[ -f /install/.nginx.lock ]]; then
        if ! grep -q proxy_cookie_path /etc/nginx/apps/qbittorrent.conf; then
            sed -r 's|(rewrite .*)|\1\n    proxy_cookie_path / "/qbittorrent/; Secure";|g' -i /etc/nginx/apps/qbittorrent.conf
            systemctl reload nginx
        fi
    fi
fi
