#!/bin/bash
if [[ ! -f /install/.airsonic.lock ]]; then
    echo_error "Airsonic not installed"
    exit 1
fi
current_v="$(unzip -p /opt/airsonic/airsonic.war META-INF/MANIFEST.MF | grep -i Implementation-Version | cut -d' ' -f 2)"
release_v="$(curl -s https://api.github.com/repos/airsonic/airsonic/releases/latest | jq -r .'tag_name')"
echo_info "Installed = $current_v\nAvailable = $release_v"
if ! ask "Upgrade Airsonic package?"; then
    exit 0
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
