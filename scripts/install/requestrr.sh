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
#shellcheck source=sources/functions/users
. /etc/swizzin/sources/functions/requestrr

user=$(_get_master_username)

# Download Requestrr
_requestrr_download

# Extract and Put into Place
echo_progress_start "Extracting archive"
unzip -q /tmp/requestrr.zip -d /opt/ >> "$log" 2>&1
rm /tmp/requestrr.zip
mv /opt/requestrr* /opt/requestrr
echo_progress_done "Archive extracted"

# Create User and set permissions
echo_progress_start "Creating requestrr user and setting permssions"
useradd --system -Md /opt/requestrr/ requestrr
chown -R requestrr:requestrr /opt/requestrr/
chmod u+x /opt/requestrr/Requestrr.WebApi
echo_progress_done "Requestrr user has been created & permissions set."

# Apply Requestrr Config from sources/function/requestrr
echo_progress_start "Applying Requestrr config..."
_requestrr_config
echo_progress_done "Requestrr config applied."

echo_progress_start "Installing Systemd service"
requestrr_systemd
echo_progress_done "Installing Systemd service"

# Nginx Changes
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Installing nginx configuration"
    bash /usr/local/bin/swizzin/nginx/requestrr.sh
    systemctl -q reload nginx
    echo_progress_done "Nginx configured"
else
    echo_info "Requestrr will be available on port 4545. Secure your installation manually through the web interface."
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
fi

systemctl -q daemon-reload
systemctl -q enable --now requestrr
touch /install/.requestrr.lock

echo_progress_done "Requestrr service installed and enabled"
