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
#shellcheck source=sources/functions/requestrr
. /etc/swizzin/sources/functions/requestrr

_requestrr_download

echo_progress_start "Extracting archive"
unzip -q /tmp/requestrr.zip -d /opt/ >> "$log" 2>&1
rm /tmp/requestrr.zip
mv /opt/requestrr* /opt/requestrr
echo_progress_done "Archive extracted"

echo_progress_start "Creating requestrr user and setting permssions"
useradd --system -d /opt/requestrr/ requestrr
chown -R requestrr:requestrr /opt/requestrr/
chmod u+x /opt/requestrr/Requestrr.WebApi
echo_progress_done "Requestrr user has been created & permissions set."

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
cat > /opt/requestrr/appsettings.json << SET
{
  "Logging": {
    "LogLevel": {
      "Default": "None"
    }
  },
  "AllowedHosts": "*"
}
SET

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx configuration"
    bash /usr/local/bin/swizzin/nginx/requestrr.sh
    systemctl -q reload nginx
    echo_progress_done "Nginx configured"
else
    echo_info "Requestrr will be available on port 4545. Secure your installation manually through the web interface."
fi

systemctl -q daemon-reload
systemctl -q enable --now requestrr
touch /install/.requestrr.lock

echo_progress_done "Requestrr service installed and enabled"
