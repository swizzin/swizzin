#!/bin/bash
# Flood for rtorrent installation script for swizzin
# Author: liara

_install() {

    #shellcheck source=sources/functions/npm
    . /etc/swizzin/sources/functions/npm
    npm_install

    sudo useradd --create-home --shell /bin/false flood -d /opt/flood
    echo_progress_start "Installing flood"
    npm install --global flood >> "$log" 2>&1
    echo_progress_done "Flood installed"

}

_systemd() {
    cat > /etc/systemd/system/flood.service << EOF
[Unit]
Description=Flood Web UI
After=network.target

[Service]
WorkingDirectory=~
ExecStart=/usr/bin/flood -p 3006
User=flood

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable flood --now -q
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/flood.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
    else
        sed '/ExecStart=/ s/$/ --host=0.0.0.0' -i /etc/systemd/system/flood.service
        echo_info "flood will run on port 3006"
    fi
}

_permissions() {
    : # TODO fix permission to sock files here maybe?
}

_install
_systemd
_nginx
_permissions

echo_success "Flood installed"
echo_info "Please finish the setup of flood in the browser"
touch /install/.flood.lock
