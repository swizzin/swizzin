#!/bin/bash

if [[ -f /install/.sonarrold.lock ]]; then
    box install sonarr
else
    if [[ -f /install/sonarr.lock ]]; then
        echo_warn "Please use apt in order to upgrade sonarr to the lastest version"
        exit
    fi
    echo_warn "Cannot perform sonarr v2 to v3 migration."
    exit 1
fi
