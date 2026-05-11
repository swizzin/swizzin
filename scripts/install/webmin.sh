#! /bin/bash
# shellcheck disable=SC2024
# Webmin installer
# flying_sausages for swizzin 2020

_install_webmin() {
    echo_progress_start "Installing Webmin repo"
    # Clean up old apt source/key artifacts that can trigger unsigned repo errors.
    rm -f /etc/apt/sources.list.d/webmin.list \
        /etc/apt/sources.list.d/webmin.list.save \
        /etc/apt/trusted.gpg.d/webmin*.gpg \
        /usr/share/keyrings/webmin-archive-keyring.gpg

    install -d -m 0755 /usr/share/keyrings
    curl -fsSL https://download.webmin.com/developers-key.asc | gpg --dearmor -o /usr/share/keyrings/webmin-archive-keyring.gpg 2>> "${log}"
    chmod 0644 /usr/share/keyrings/webmin-archive-keyring.gpg

    cat > /etc/apt/sources.list.d/webmin.list << EOF
deb [signed-by=/usr/share/keyrings/webmin-archive-keyring.gpg] https://download.webmin.com/download/newkey/repository stable contrib
EOF
    echo_progress_done "Repo added"
    apt_update
    apt_install webmin
}

_install_webmin
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /etc/swizzin/scripts/nginx/webmin.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Webmin will run on port 10000"
fi

echo_success "Webmin installed"
echo_info "Please use any account with sudo permissions to log in"

touch /install/.webmin.lock
