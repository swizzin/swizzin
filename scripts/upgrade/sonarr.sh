#!/bin/bash

if [[ ! -f /install/.sonarrold.lock ]]; then
    echo_error "Sonarr v2 not detected. Exiting!"
    exit 1
fi

box install sonarr
