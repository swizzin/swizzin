#!/bin/bash

# Script by @ComputerByte
# For Komga Installs
install() {
    user=$(_get_master_username)
    echo_progress_start "Making data directory and owning it to ${user}"
    mkdir -p "/opt/komga"
    chown -R "$user":"$user" /opt/komga
    dlurl="$(curl -sNL https://api.github.com/repos/gotson/komga/releases/latest | jq -r '.assets[]?.browser_download_url | select(contains("jar"))')"
    wget "$dlurl" -o /opt/komga/komga.jar
    echo_progress_done "Data Directory created and owned."
}

systemd() {
    echo_progress_start "Installing systemd service file"
    cat > /etc/systemd/system/komga.service <<- SERV
[[Unit]
Description=Komga server

[Service]
WorkingDirectory=/opt/komga/
ExecStart=/usr/bin/java -jar -Xmx4g /opt/komga/komga.jar --server.servlet.context-path="/komga/" --server.port="6800"
User=${user}
Type=simple
Restart=on-failure
RestartSec=10
StandardOutput=null
StandardError=syslog
[Install]
WantedBy=multi-user.target
SERV
    systemctl enable --now komga -q
    echo_progress_done "Komga service installed"
}

nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/komga.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
    else
        echo_info "Komga will be available on port 6800. Secure your installation manually through the web interface."
    fi
}

install
systemd
nginx

touch /install/.komga.lock
echo_success "Komga installed"
