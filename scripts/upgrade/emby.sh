#!/bin/bash
# Simple tool to grab the latest release of emby

. /etc/swizzin/sources/functions/utils
latest=$(github_latest_version MediaBrowser/Emby.Releases)
current=$(dpkg-query -f='${Version}' --show emby-server)

if dpkg --compare-versions ${latest} gt ${current}; then
    echo_info "Upgrading Emby"
    wget -O /tmp/emby.dpkg https://github.com/MediaBrowser/Emby.Releases/releases/download/${latest}/emby-server-deb_${latest}_$(_os_arch).deb >> $log 2>&1 || {
        echo_error "Emby failed to download"
        exit 1
    }
    dpkg -i /tmp/emby.dpkg >> ${log} 2>&1 || {
        echo_error "Emby failed to install"
    }
    rm /tmp/emby.dpkg
else
    echo_info "Emby is already up to date!"
fi
