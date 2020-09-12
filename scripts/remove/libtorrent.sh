#!/bin/bash
#libtorrent remove script

if [[ -f /install/.deluge.lock ]] || [[ -f /install/.qbittorrent.lock ]]; then
    echo "It looks like Deluge or qBittorrent is still installed. Not proceeding."
    exit 1
fi

apt_remove --purge libtorrent-rasterbar*
dpkg -r libtorrent > /dev/null 2>&1
dpkg -r libtorrent-rasterbar > /dev/null 2>&1
dpkg -r python-libtorrent > /dev/null 2>&1
dpkg -r python3-libtorrent > /dev/null 2>&1
dpkg -r deluge-common > /dev/null 2>&1
rm /install/.libtorrent.lock