#!/bin/bash
# Simple tool to grab the latest release of emby

. /etc/swizzin/sources/functions/utils
current=$(github_latest_version MediaBrowser/Emby.Releases)
wget -O /tmp/emby.dpkg https://github.com/MediaBrowser/Emby.Releases/releases/download/${current}/emby-server-deb_${current}_$(_os_arch).deb >> $log 2>&1 || {
    echo_error "Emby failed to download"
    exit 1
}
dpkg -i /tmp/emby.dpkg >> ${log} 2>&1 || {
    echo_error "Emby failed to install"
}
rm /tmp/emby.dpkg
