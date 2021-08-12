#!/bin/bash
# autobrr upgrader for swizzin
# Author: ludviglundgren

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

app_name="autobrr"
app_dir="/opt/${app_name}"
app_lockname="${app_name//-/}"

if [[ ! -f "/install/.$app_lockname.lock" ]]; then
    echo_error "$app_name doesn't appear to be installed!"
    exit 1
fi

_upgrade_autobrr() {

    echo_progress_start "Downloading release archive"

    case "$(_os_arch)" in
        "amd64") arch='x86_64' ;;
        "arm64") arch="arm64" ;;
        "armhf") arch="armv6" ;;
        *)
            echo_error "Arch not supported"
            exit 1
        ;;
    esac

    latest=$(curl -sL https://api.github.com/repos/autobrr/autobrr/releases/latest | grep "linux_$arch" | grep browser_download_url | cut -d \" -f4) || {
        echo_error "Failed to query GitHub for latest version"
        exit 1
    }

    if ! curl "$latest" -L -o "/tmp/$app_name.tar.gz" >> "$log" 2>&1; then
        echo_error "Download failed, exiting"
        exit 1
    fi

    echo_progress_done "Archive downloaded"

   if [[ $(systemctl is-active $app_name) == "active" ]]; then
       wasActive="true"
       echo_progress_start "Shutting down $app_name before upgrading"
       systemctl stop "$app_name"
       echo_progress_done
   fi

    echo_progress_start "Extracting archive"

    tar xfv "/tmp/$app_name.tar.gz" --directory /opt/$app_name >> "$log" 2>&1 || {
        echo_error "Failed to extract"
        exit 1
    }
    rm -rf "/tmp/$app_name.tar.gz"
    chown -R "${user}": "$app_dir"
    echo_progress_done "Archive extracted"


    if [[ $wasActive = "true" ]]; then
        echo_progress_start "Restarting $app_name"
        systemctl start "$app_name"
        echo_progress_done
    fi
}

_upgrade_autobrr

echo_success "$app_name upgraded"
