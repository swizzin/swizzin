#!/usr/bin/env bash
#
# authors: SavageCore
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)

# Add the jfa-go official repository and key to our installation so we can use apt-get to install it.
echo_progress_start "Setting up jfa-go repository"
curl -s "https://apt.hrfee.dev/hrfee.pubkey.gpg" | gpg --dearmor > /usr/share/keyrings/jfa-go-archive-keyring.gpg 2>> "${log}"
echo "deb [signed-by=/usr/share/keyrings/jfa-go-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://apt.hrfee.dev trusty main" > /etc/apt/sources.list.d/jfa-go.list
echo_progress_done "Repository added"

# Install jfa-go using apt functions.
# Install crudini to edit the config file
apt_update
apt_install jfa-go crudini

# Configure the nginx proxypass using positional parameters.
if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/jfago.sh
    systemctl -q restart nginx.service
else
    echo_info "jfago will run on port 8056"
fi

# Create jfago user
useradd -r jfago -s /usr/sbin/nologin > /dev/null 2>&1

# Create systemd service
echo_progress_start "Setting up systemd service"
jfagobinary=$(which jfa-go)
mkdir -p /opt/jfago/config/
chown jfago: /opt/jfago -R

cat > /etc/systemd/system/jfago.service << EOF
[Unit]
Description=An account management system for Jellyfin.
After=network.target
[Service]
ExecStart=${jfagobinary} -config /opt/jfago/config/config.ini -data /opt/jfago/config/
User=jfago

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload -q
echo_progress_done "Service installed"

# Start the service
echo_progress_start "Enabling and starting jfago to create config file"
systemctl -q enable jfago --now
echo_progress_done

crudini --set /opt/jfago/config/config.ini ui url_base /jfa-go

# This file is created after installation to prevent reinstalling. You will need to remove the app first which deletes this file.
touch /install/.jfago.lock
echo_success "jfago installed but not configured"
echo_info "Edit /opt/jfago/config/config.ini to configure and then restart the service with systemctl restart jfago"
exit
