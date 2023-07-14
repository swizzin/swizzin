#!/bin/bash
# Simple tool to grab the latest release of emby

. /etc/swizzin/sources/functions/utils
dl_url=$(github_release_url MediaBrowser/Emby.Releases "$(_os_arch).deb")
current=$(dpkg-query -f='${Version}' --show emby-server)

if dpkg --compare-versions ${github_Emby_tag} gt ${current}; then
    echo_info "Upgrading Emby"
    wget -O /tmp/emby.dpkg "$dl_url" >> $log 2>&1 || {
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
