#!/bin/bash

# Script by @ComputerByte
# For Komga Installs

user=$(_get_master_username)

echo_progress_start "Making data directory and owning it to ${user}"
mkdir -p "/opt/komga"
chown -R "$user":"$user" /opt/komga
cd "/opt/komga" || exit
wget "https://github.com/gotson/komga/releases/download/untagged-6ed960e7d43ebfe31fe8/komga-0.90.0.jar" >>$log 2>&1
echo_progress_done "Data Directory created and owned."

echo_progress_start "Installing systemd service file"
cat >/etc/systemd/system/komga.service <<-SERV
[[Unit]
Description=Komga server

[Service]
WorkingDirectory=/opt/komga/
ExecStart=/usr/bin/java -jar -Xmx4g komga-0.90.0.jar --server.servlet.context-path="/komga/"
User=${user}
Type=simple
Restart=on-failure
RestartSec=10
StandardOutput=null
StandardError=syslog
[Install]
WantedBy=multi-user.target
SERV
echo_progress_done "Komga service installed"

# This checks if nginx is installed, if it is, then it will install nginx config for komga
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx config"
    cat >/etc/nginx/apps/komga.conf <<-NGX
location /komga {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:8080/komga;
}
NGX
    # Reload nginx
    systemctl reload nginx
else
    echo_info "Komga will be available on port 8080. Secure your installation manually through the web interface."
    echo_progress_done "Nginx config applied"
fi

touch /install/.komga.lock
systemctl restart panel >>$log 2>&1
echo_success "Komga installed"
