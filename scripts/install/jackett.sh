#!/bin/bash
#
# [Quick Box :: Install Jackett package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | d2dyno
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/os
. /etc/swizzin/sources/functions/os
#shellcheck source=sources/functions/app_port
. /etc/swizzin/sources/functions/app_port
#shellcheck source=sources/functions/ip
. /etc/swizzin/sources/functions/ip
# Get our main user credentials to use when bootstrapping filebrowser.
username="$(_get_master_username "${username}")"
password="$(_get_master_password)"
# Get our app port using the install script name as the app name
app_proxy_port="$(_get_app_port "$(basename -- "$0")")"

username=$(_get_master_username)

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
