#!/bin/bash
# Simple tool to grab the latest release of emby

current=$(curl -L -s -H 'Accept: application/json' https://github.com/MediaBrowser/Emby.Releases/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
cd /tmp
wget -q -O emby.dpkg https://github.com/MediaBrowser/Emby.Releases/releases/download/${current}/emby-server-deb_${current}_amd64.deb
dpkg -i emby.dpkg >> /dev/null 2>&1
rm emby.dpkg