#!/bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
users=($(_get_user_list))

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
        if [ -z "$SWIZDB_BIND_ENFORCE" ]; then
            if ! SWIZDB_BIND_ENFORCE="$(swizdb get qbittorrent/bindEnforce)"; then
                SWIZDB_BIND_ENFORCE=True
                swizdb set "qbittorrent/bindEnforce" "$SWIZDB_BIND_ENFORCE"
            fi
            else
                echo_info "Setting qbittorrent/bindEnforce = $SWIZDB_BIND_ENFORCE"
                swizdb set "qbittorrent/bindEnforce" "$SWIZDB_BIND_ENFORCE"
            fi
        fi
        if $(swizdb get qbittorrent/bindEnforce); then
            for user in ${users[@]}; do
                if ! grep -q "WebUI\\\Address=127.0.0.1" /home/${user}/.config/qBittorrent/qBittorrent.conf; then
                    wasActive=$(systemctl is-active qbittorrent@${user})
                    echo_log_only "Active: ${wasActive}"
                    if [[ $wasActive == "active" ]]; then
                        echo_log_only "Stopping qBittorrent for ${user}"
                        systemctl stop -q "qbittorrent@${user}"
                    fi
                    sed -i 's|WebUI\\\Address*|WebUI\\\Address=127.0.0.1|g' /home/${user}/.config/qBittorrent/qBittorrent.conf
                    systemctl start "qbittorrent@${user}"
                    if [[ $wasActive == "active" ]]; then
                        echo_log_only "Activating qBittorrent for ${user}"
                        systemctl start "qbittorrent@${user}" -q
                    fi
                fi
            done
        fi
    fi          
fi
