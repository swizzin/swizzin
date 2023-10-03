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
            echo_progress_start "Updating qBittorrent nginx config"
            sed -r 's|(rewrite .*)|\1\n    proxy_cookie_path / "/qbittorrent/; Secure";|g' -i /etc/nginx/apps/qbittorrent.conf
            systemctl reload nginx
            echo_progress_done
        fi
        users=($(_get_user_list))
        for user in ${users[@]}; do
            if grep -q 'WebUI\\Address=\*' /home/${user}/.config/qBittorrent/qBittorrent.conf; then
                echo_warn "qBittorrent WebUI for ${user} is bound to all interfaces and can be accessed without the nginx proxy. The updater will not update this default for you in the event you want to keep it this way. You can fix this yourself in the qBittorrent WebUI: Settings > Web UI > Web User Interface > IP Address: 127.0.0.1. You can suppress this warning by changing your bind address to 0.0.0.0, though this may interfere with ipv6 access. Restart qBittorrent after making the change."
            fi
        done
    fi
fi
