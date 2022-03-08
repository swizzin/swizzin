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
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

username=$(cut -d: -f1 < /root/.master.info)
case "$(_os_arch)" in
    amd64)
        arch='AMDx64'
        ;;
    arm64)
        arch="ARM64"
        ;;
    armhf)
        arch="ARM32"
        ;;
    *)
        echo_error "Arch not supported for jackett"
        ;;
esac

version=$(github_latest_version "Jackett/Jackett")
password=$(cut -d: -f2 < /root/.master.info)

echo_progress_start "Downloading and extracting jackett"
cd /home/$username
wget "https://github.com/Jackett/Jackett/releases/download/${version}/Jackett.Binaries.Linux${arch}.tar.gz" >> "$log" 2>&1
tar -xvzf Jackett.Binaries.*.tar.gz > /dev/null 2>&1
rm -f Jackett.Binaries.*.tar.gz
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
else
    echo_info "Jackett will run on port 9117"
fi

systemctl enable -q --now jackett@${username} 2>&1 | tee -a $log

sleep 10

echo_progress_start "Setting admin password"
cookie=$(curl -v 127.0.0.1:9117/jackett/UI/Dashboard -L 2>&1 | grep -m1 Set-Cookie | awk '{printf $3}' | sed 's/;//g')
curl http://127.0.0.1:9117/jackett/api/v2.0/server/adminpassword -H 'Content-Type: application/json' -H 'Cookie: '${cookie}'' --data-binary '"'${password}'"' >> $log 2>&1
echo_progress_done

touch /install/.jackett.lock

echo_success "Jackett installed"
