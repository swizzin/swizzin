#!/bin/bash
if [[ ! -f /install/.airsonic.lock ]]; then
	echo_error "Airsonic not installed"
	exit 1
fi

echo_progress_start "Downloading airsonic binary"
dlurl=$(curl -s https://api.github.com/repos/airsonic/airsonic/releases/latest | grep "browser_download_url" | grep "airsonic.war" | head -1 | cut -d\" -f 4)
echo_log_only "dlurl = $dlurl"
if ! wget "$dlurl" -O /tmp/airsonic.war >> "$log" 2>&1; then
	echo_error "Download failed!"
	exit 1
fi
mv /tmp/airsonic.war /opt/airsonic/airsonic.war
chown -R airsonic:airsonic /opt/airsonic
echo_progress_done "Airosnic binray replaced"
