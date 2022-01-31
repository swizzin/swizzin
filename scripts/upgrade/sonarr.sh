#!/bin/bash

if [[ -f /install/.sonarrold.lock ]]; then
    box install sonarr
else
    if [[ -f /install/sonarr.lock ]]; then
        echo_warn "Please upgrade Sonarr from within the UI"
        exit
    fi
    echo_warn "Cannot perform sonarr v2 to v3 migration."
    exit 1
fi
