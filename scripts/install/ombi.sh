#!/bin/bash
# Ombi installer
# Swizzin gplv3 and all that

function _sources() {
    echo_progress_start "Installing ombi apt sources"
    echo "deb https://apt.ombi.app/master jessie main" > /etc/apt/sources.list.d/ombi.list
    wget -qO - https://apt.ombi.app/pub.key | apt-key add - >> "$log" 2>&1
    echo_progress_done "Sources installed"
    apt_update
}

function _install() {
    apt_install ombi

    mkdir -p /etc/systemd/system/ombi.service.d
    cat > /etc/systemd/system/ombi.service.d/override.conf << CONF
[Service]
ExecStart=
ExecStart=/opt/Ombi/Ombi --host http://0.0.0.0:3000 --storage /etc/Ombi
CONF
    systemctl daemon-reload
    systemctl enable --now -q ombi
}

function _nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /usr/local/bin/swizzin/nginx/ombi.sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "Ombi is accessible under port 3000"
    fi

}

_sources
_install
_nginx
touch /install/.ombi.lock
echo_success "Ombi installed"
echo_info "Please continue setting up your administrator user through the browser"
