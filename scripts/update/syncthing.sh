#!/bin/bash
# Syncthing Updater

if [[ -f /install/.syncthing.lock ]]; then
    if grep -q "release" /etc/apt/sources.list.d/syncthing.list; then
        echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] http://apt.syncthing.net/ syncthing stable" > /etc/apt/sources.list.d/syncthing.list
    fi
fi
