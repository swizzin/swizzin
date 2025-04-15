#!/bin/bash
# Tailscale Installer for Swizzin
# This script installs Tailscale on a Swizzin server.

. /etc/swizzin/sources/functions/letsencrypt

if [[ -f /install/.tailscale.lock ]]; then
    echo_error "Tailscale is already installed. Please remove /install/.tailscale.lock to reinstall."
fi

curl -fsSL https://tailscale.com/install.sh | sh >> $log 2>&1

echo_query "What would you like your machine hostname to be on your tailnet?" "$(hostname)"
read -re ts_hostname

echo_info "Please use the link below to authenticate your Tailscale account."
tailscale up --hostname="${ts_hostname}"

if ask "Would you like to run an exit node?"; then
    tailscale up --advertise-exit-node
fi

if [[ -f /install/.nginx.lock ]]; then
    if ask "Would you like to bind your NGINX server to your Tailscale IP / hostname ${ts_hostname}?"; then
        echo_progress_start "Binding default server to Tailscale IP"
        tailscale_ipv4=$(tailscale ip -4 | head -n1)
        tailscale_ipv6=$(tailscale ip -6 | head -n1)
        sed -i "s|listen \[[^]]*\]:80.*|listen [${tailscale_ipv6}]:80 default_server;|g" /etc/nginx/sites-enabled/default
        sed -i "s|listen \[[^]]*\]:443.*|listen [${tailscale_ipv6}]:443 ssl http2;|g" /etc/nginx/sites-enabled/default
        sed -i "s|listen \([0-9.]*:\)\?80.*|listen ${tailscale_ipv4}:80 default_server;|g" /etc/nginx/sites-enabled/default
        sed -i "s|listen \([0-9.]*:\)\?443.*|listen ${tailscale_ipv4}:443 ssl http2;|g" /etc/nginx/sites-enabled/default
        systemctl reload nginx >> $log 2>&1
        echo_progress_done "Default server bound to ${tailscale_ipv4} and ${tailscale_ipv6}"

        if ask "Would you like Tailscale to generate TLS certificates for your device?"; then
            echo_progress_start "Generating TLS certificates for Tailscale IP"
            ts_renewal
            chmod 700 /etc/nginx/ssl/
            chown -R www-data:www-data "/etc/nginx/ssl/${ts_hostname}"
            sed -i "s|server_name .*;|server_name ${ts_hostname};|g" /etc/nginx/sites-enabled/default
            sed -i "s|ssl_certificate .*;|ssl_certificate /etc/nginx/ssl/${ts_hostname}/cert.pem;|g" /etc/nginx/sites-enabled/default
            sed -i "s|ssl_certificate_key .*;|ssl_certificate_key /etc/nginx/ssl/${ts_hostname}/key.pem;|g" /etc/nginx/sites-enabled/default
            echo_progress_done
            echo_progress_start "Installing renewal job"
            ts_cron="23 2 */45 * * bash -c \"source /etc/swizzin/sources/globals.sh && source /etc/swizzin/sources/functions/letsencrypt && ts_renewal\""
            crontab -l 2> /dev/null | grep -F "$ts_cron" > /dev/null
            if [ $? -ne 0 ]; then
                (
                    crontab -l 2> /dev/null
                    echo "$ts_cron"
                ) | crontab -
                echo_progress_done
            else
                echo_error "Cron job already exists. Skipping."
            fi
        fi
        echo_progress_start "Applying your changes to nginx"
        systemctl reload nginx >> $log 2>&1
        echo_progress_done
    fi
fi

echo_progress_done "Tailscale installed and configured successfully."
