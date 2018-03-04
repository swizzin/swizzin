#!/bin/bash

find /home -mindepth 1 -maxdepth 1 -type d -exec chmod 750 {} \;

if [[ -f /install/.plex.lock ]]; then
    master=$(cat /root/.master.info | cut -d: -f1)
    if [[ -z $(groups plex | grep ${master}) ]]; then
        usermod -a -G ${master} plex
    fi
fi