#!/bin/bash
# Flood for rtorrent installation script for swizzin
# Author: liara

_install() {
    #shellcheck source=sources/functions/npm
    . /etc/swizzin/sources/functions/npm
    npm_install

    echo_progress_start "Installing flood"
    npm install --global flood >> "${log}" 2>&1
    echo_progress_done "Flood installed"
}

_systemd() {
    cat > /etc/systemd/system/flood@.service << EOF
[Unit]
Description=Flood Web UI
After=network.target

[Service]
EnvironmentFile=/home/%I/.config/flood/env
ExecStart=/usr/bin/env flood -p \${FLOOD_PORT} -d /home/%I/.config/flood --allowedpath=/home/%I
User=%I

[Install]
WantedBy=multi-user.target
EOF
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/flood.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
    else
        sed -i '/ExecStart=/ s/$/ --host=0.0.0.0/' /etc/systemd/system/flood@.service
    fi
}

_flood_port() {
    flood_port=$(port 3300 3400)
    mkdir -p /home/${user}/.config/flood
    echo "FLOOD_PORT=${flood_port}" > /home/${user}/.config/flood/env
    chown -R ${user}: /home/${user}/.config/flood
}

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ -n $1 ]]; then
    echo_progress_start "Assigning flood port to $user"
    user=$1
    _flood_port
    _nginx
    echo_progress_done "Done"
    exit 0
fi

_install
_systemd

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    echo_progress_start "Assigning flood port to $user and starting service"
    _flood_port
    systemctl enable --now flood@${user} >> ${log} 2>&1
    echo_progress_done "Done"
done

_nginx

echo_success "Flood installed"
touch /install/.flood.lock
