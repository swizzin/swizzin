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

. /etc/swizzin/sources/functions/utils
. /etc/swizzin/sources/functions/os

username=$(_get_master_username)

jackett_latest_version="$(git ls-remote -t --sort=-v:refname --refs https://github.com/Jackett/Jackett.git | awk '{sub("refs/tags/v", "");sub("(.*)(rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | head -n 1)"
jackett_url="https://github.com/Jackett/Jackett/releases/download/v${jackett_latest_version}/Jackett.Binaries.LinuxAMDx64.tar.gz"

case "$(_os_arch)" in
    "amd64") jackett_arch="AMDx64" ;;
    "arm32") jackett_arch="ARM32" ;;
    "arm64") jackett_arch="ARM64" ;;
    *)
        echo_error "Arch not supported"
        exit 1
        ;;
esac

jackett_url="https://github.com/Jackett/Jackett/releases/download/v${jackett_latest_version}/Jackett.Binaries.Linux${jackett_arch}.tar.gz"

echo_progress_start "Downloading and extracting jackett"
cd "/home/$username" || exit
wget "$jackett_url" &>> "$log"
tar -xvzf Jackett.Binaries.LinuxAMDx64.tar.gz &>> "$log"
rm -f Jackett.Binaries.LinuxAMDx64.tar.gz
chown ${username}.${username} -R Jackett
echo_progress_done

echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/jackett@.service << JAK
[Unit]
Description=jackett for %i
After=network.target

[Service]
SyslogIdentifier=jackett.%i
Type=simple
User=%i
WorkingDirectory=/home/%i/Jackett
ExecStart=/bin/sh -c "/home/%i/Jackett/jackett_launcher.sh"
Restart=always
RestartSec=5
TimeoutStopSec=20
[Install]
WantedBy=multi-user.target
JAK

if [[ ! -f /home/${username}/Jackett/jackett_launcher.sh ]]; then
    cat > /home/${username}/Jackett/jackett_launcher.sh << 'JL'
#!/bin/bash
user=$(whoami)

/home/${user}/Jackett/jackett

while pgrep -u ${user} JackettUpdater > /dev/null ; do
     sleep 1
done

echo "Jackett update complete"
JL
    chmod +x /home/${username}/Jackett/jackett_launcher.sh
fi
echo_progress_done "Service file installed"

echo_progress_start "Configuring jackett"
mkdir -p /home/${username}/.config/Jackett
cat > /home/${username}/.config/Jackett/ServerConfig.json << JSC
{
  "Port": 9117,
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

chown ${username}.${username} -R /home/${username}/.config

echo_progress_done "Jackett configured"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx config"
    bash /usr/local/bin/swizzin/nginx/jackett.sh
    systemctl reload nginx >> $log 2>&1
    echo_progress_done "Nginx configured"
fi

systemctl enable -q --now jackett@${username} 2>&1 | tee -a $log

sleep 10

touch /install/.jackett.lock

echo_success "Jackett installed"
