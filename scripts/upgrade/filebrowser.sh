#!/bin/bash

if [[ ! -f /install/.filebrowser.lock ]]; then
    echo_error "Filebrowser does not appear to be installed!"
    exit 1
fi

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/os
. /etc/swizzin/sources/functions/os

username=$(_get_master_username)

if [[ "$(systemctl is-active filebrowser)" == "active" ]]; then
    systemctl stop filebrowser &>> "${log}"
fi

app_latest_version="$(git ls-remote -t --sort=-v:refname --refs https://github.com/filebrowser/filebrowser.git | awk '{sub("refs/tags/v", "");sub("(.*)(rc|alpha|beta)(.*)", ""); print $2 }' | awk '!/^$/' | head -n 1)"
case "$(_os_arch)" in
    "amd64") app_arch="amd64" ;;
    "armhf") app_arch="armv7" ;;
    "arm64") app_arch="arm64" ;;
    *)
        echo_error "Arch not supported"
        exit 1
        ;;
esac
app_url="https://github.com/filebrowser/filebrowser/releases/download/v${app_latest_version}/linux-${app_arch}-filebrowser.tar.gz"
#
# Download and extract the files to the desired location.
echo_progress_start "Downloading and extracting filebrowser"
wget -O "/tmp/filebrowser.tar.gz" "${app_url}" &>> "${log}"
mkdir -p "/opt/filebrowser"
tar -xvzf "/tmp/filebrowser.tar.gz" -C "/opt/filebrowser" filebrowser &>> "${log}"
rm -f "/tmp/filebrowser.tar.gz" &>> "${log}"
echo_progress_done
#
echo_progress_start "Setting correct permissions"
chown -R "${username}:${username}" "/home/${username}/.config" &>> "${log}"
chmod 700 "/opt/filebrowser/filebrowser" &>> "${log}"
chown -R "${username}.${username}" "/opt/filebrowser" &>> "${log}"
echo_progress_done

# Update nginx stuff
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Updating nginx config"
    bash "/usr/local/bin/swizzin/nginx/filebrowser.sh" 'upgrade'
    systemctl reload nginx &>> "${log}"
    echo_progress_done "Nginx config updated"
fi
#
# Start the service.
if [[ "$(systemctl is-active filebrowser)" =~ (inactive|failed) ]]; then
    systemctl start filebrowser &>> "${log}"
fi
