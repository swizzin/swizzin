#!/bin/bash

if [[ ! -f /install/.sonarrv2-old.lock ]]; then
    echo_error "Sonarr not detected. Exiting!"
    exit 1
fi

box install sonarrv3
