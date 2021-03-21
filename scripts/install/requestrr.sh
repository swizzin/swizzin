#!/bin/bash
# Requestrr installation
# Author: Brett
# Copyright (C) 2021 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#shellcheck source="sources/functions/os"
. /etc/swizzin/sources/functions/os

user=$(cut -d: -f1 < /root/.master.info)

echo_progress_start "Downloading source files"
case "$(_os_arch)" in
    "amd64") wget -qO "/tmp/requestrr.zip" "$(curl -sNL https://api.github.com/repos/darkalfx/requestrr/releases/latest | grep -Po 'ht(.*)linux-x64(.*)zip')" >> ${log} 2>&1 ;;
    "armhf") wget -qO "/tmp/requestrr.zip" "$(curl -sNL https://api.github.com/repos/darkalfx/requestrr/releases/latest | grep -Po 'ht(.*)linux-arm(.*)zip')" >> ${log} 2>&1 ;;
    "arm64") wget -qO "/tmp/requestrr.zip" "$(curl -sNL https://api.github.com/repos/darkalfx/requeAstrr/releases/latest | grep -Po 'ht(.*)linux-arm64(.*)zip')" >> ${log} 2>&1 ;;
    *)
        echo_error "Arch not supported"
        exit 1
        ;;
esac

echo_progress_done "Source downloaded"

echo_progress_start "Extracting archive"
unzip /tmp/requestrr.zip -d /opt/ >> "$log" 2>&1
mv requestrr* requestrr
echo_progress_done "Archive extracted"

touch /install/.requestrr.lock

echo_progress_start "Creating requestrr user"
useradd -M --shell=/bin/false requestrr
chown -R requestrr:${user} /opt/requestrr
chmod +x /opt/requestrr/Requestrr.WebApi
echo_progress_done "Requestrr user created"

echo_progress_start "Applying Requestrr config..."
cat > /opt/requestrr/SettingsTemplate.json << CFG
{
  "Authentication": {
    "Username": "",
    "Password": "",
    "PrivateKey": "[PRIVATEKEY]"
  },
  "ChatClients": {
    "Discord": {
      "BotToken": "",
      "ClientId": "",
      "StatusMessage": "!help",
      "TvShowRoles": [],
      "MovieRoles": [],
      "MonitoredChannels": [],
      "EnableRequestsThroughDirectMessages": false,
      "AutomaticallyNotifyRequesters": true,
      "NotificationMode": "PrivateMessages",
      "NotificationChannels": [],
      "AutomaticallyPurgeCommandMessages": false,
      "DisplayHelpCommandInDMs": true
    }
  },
  "DownloadClients": {
    "Ombi": {
      "Hostname": "",
      "Port": 3579,
      "ApiKey": "",
      "ApiUsername": "",
      "BaseUrl": "",
      "UseSSL": false,
      "Version": "3"
    },
    "Overseerr": {
      "Hostname": "",
      "Port": 5055,
      "ApiKey": "",
      "DefaultApiUserID": "",
      "UseSSL": false,
      "Version": "1"
    },
    "Radarr": {
      "Hostname": "",
      "Port": 7878,
      "ApiKey": "",
      "BaseUrl": "",
      "MovieProfileId": "1",
      "MovieRootFolder": "",
      "MovieMinimumAvailability": "",
      "MovieTags": [],
      "AnimeProfileId": "1",
      "AnimeRootFolder": "",
      "AnimeMinimumAvailability": "",
      "AnimeTags": [],
      "SearchNewRequests": true,
      "MonitorNewRequests": true,
      "UseSSL": false,
      "Version": "2"
    },
    "Sonarr": {
      "Hostname": "",
      "Port": 8989,
      "ApiKey": "",
      "BaseUrl": "",
      "TvProfileId": "1",
      "TvRootFolder": "",
      "TvTags": [],
      "TvLanguageId": "1",
      "TvUseSeasonFolders": true,
      "AnimeProfileId": "1",
      "AnimeRootFolder": "",
      "AnimeTags": [],
      "AnimeLanguageId": "1",
      "AnimeUseSeasonFolders": true,
      "SearchNewRequests": true,
      "MonitorNewRequests": true,
      "UseSSL": false,
      "Version": "3"
    }
  },
  "BotClient": {
    "Client": "",
    "CommandPrefix": "!"
  },
  "Movies": {
    "Client": "Disabled",
    "Command": "movie"
  },
  "TvShows": {
    "Client": "Disabled",
    "Command": "tv",
    "Restrictions": "None"
  },
  "Port": 4545,
  "BaseUrl" : "/requestrr",
  "Version": "1.12.0"
}
CFG

echo_progress_done "Requestrr config applied."

echo_progress_start "Installing Systemd service"
cat > /etc/systemd/system/requestrr.service << EOF
[Unit]
Description=Requestrr Daemon
After=syslog.target network.target

[Service]
User=requestrr
Type=simple
WorkingDirectory=/opt/requestrr/
ExecStart=/opt/requestrr/Requestrr.WebApi
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl -q daemon-reload
systemctl enable --now -q requestrr
sleep 1
echo_progress_done "Requestrr service installed and enabled"

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx configuration"
    #TODO what is this sleep here for? See if this can be fixed by doing a check for whatever it needs to
    sleep 10
    bash /usr/local/bin/swizzin/nginx/requestrr.sh
    systemctl daemon-reload
    systemctl -q reload nginx
    systemctl restart requestrr
    echo_progress_done "Nginx configured"
else
    echo_info "Requestrr will be available on port 4545. Secure your installation manually through the web interface."
fi
