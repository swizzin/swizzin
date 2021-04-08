#!/usr/bin/env bash
#
# authors: liara userdocs
#
# GNU General Public License v3.0 or later
#
if [[ ! -f /install/.nginx.lock ]]; then
    echo_warn "Nginx is required for this application"
    exit
fi
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/os
. /etc/swizzin/sources/functions/os
#shellcheck source=sources/functions/app_port
. /etc/swizzin/sources/functions/app_port
#shellcheck source=sources/functions/ip
. /etc/swizzin/sources/functions/ip
#
username="$(_get_master_username)"                           # Get our master username
password="$(_get_user_password "${username}")"               # Get our master user's password
app_proxy_port="$(_get_app_port "$(basename -- "$0" \.sh)")" # Get the application port from an array using the name of this script
# external_ip="$(_external_ip)"                                # Get our external IP address
#
app_latest_version="$(git ls-remote -t --sort=-v:refname --refs https://github.com/Jackett/Jackett.git | awk '{sub("refs/tags/v", "");sub("(.*)(rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | head -n 1)"
case "$(_os_arch)" in
    "amd64") app_arch="AMDx64" ;;
    "armhf") app_arch="ARM32" ;;
    "arm64") app_arch="ARM64" ;;
    *)
        echo_error "Arch not supported"
        exit 1
        ;;
esac
app_url="https://github.com/Jackett/Jackett/releases/download/v${app_latest_version}/Jackett.Binaries.Linux${app_arch}.tar.gz"

echo_progress_start "Downloading and extracting jackett"
wget -qO "/tmp/Jackett.Binaries.Linux${app_arch}.tar.gz" "$app_url" &>> "$log"
tar -xvzf "/tmp/Jackett.Binaries.Linux${app_arch}.tar.gz" -C /opt &>> "$log"
rm_if_exists "/tmp/Jackett.Binaries.Linux${app_arch}.tar.gz"
chown -R "${username}:${username}" /opt/Jackett
echo_progress_done

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/jackett.service << JAK
[Unit]
Description=jackett
After=network.target

[Service]
SyslogIdentifier=jackett
User=${username}
ExecStart=/bin/bash /opt/Jackett/jackett_launcher.sh
Restart=always
RestartSec=5
TimeoutStopSec=30
[Install]
WantedBy=multi-user.target
JAK

if [[ ! -f /opt/Jackett/jackett_launcher.sh ]]; then
    cat > /opt/Jackett/jackett_launcher.sh << 'JL'
#!/bin/bash
user=$(whoami)

/opt/Jackett/jackett

while pgrep -u ${user} JackettUpdater > /dev/null ; do
    sleep 1
done

echo "Jackett update complete"
JL
    chmod +x /opt/Jackett/jackett_launcher.sh
fi
echo_progress_done "Service file installed"

echo_progress_start "Configuring jackett"
mkdir -p "/home/${username}/.config/Jackett"
cat > "/home/${username}/.config/Jackett/ServerConfig.json" << JSC
{
  "Port": ${app_proxy_port},
  "AllowExternal": true,
  "APIKey": "",
  "AdminPassword": "",
  "InstanceId": "",
  "BlackholeDir": "",
  "UpdateDisabled": false,
  "UpdatePrerelease": false,
  "BasePathOverride": "",
  "OmdbApiKey": "",
  "OmdbApiUrl": "",
  "ProxyUrl": "",
  "ProxyType": 0,
  "ProxyPort": null,
  "ProxyUsername": "",
  "ProxyPassword": "",
  "ProxyIsAnonymous": true
}
JSC

chown -R "${username}:${username}" "/home/${username}/.config"

echo_progress_done "Jackett configured"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx config"
    bash /usr/local/bin/swizzin/nginx/jackett.sh
    systemctl reload nginx &>> "$log"
    echo_progress_done "Nginx configured"
fi

systemctl enable -q --now jackett &>> "$log"

sleep 10

touch /install/.jackett.lock

echo_success "Jackett installed"
