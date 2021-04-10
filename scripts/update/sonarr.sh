#!/bin/bash
if [[ -f /install/.sonarr.lock ]]; then
    #upgrade sonarr v2 to v3
    box install sonarrv3
fi
