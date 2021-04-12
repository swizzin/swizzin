#!/bin/bash

if dpkg -l | grep nzbdrone > /dev/null 2>&1; then
        v2present=true
fi
if [[ -f /install/.sonarr.lock ]] && [[ $v2present == "true" ]] ; then
    #update lock file
    rm /install/.sonarr.lock
    touch /install/.sonarrv2-old.lock
fi
if [[ -f /install/.sonarrv2-old.lock ]]; then
    #upgrade sonarr v2 to v3
    box install sonarrv3
fi
if [[ -f /install/.sonarrv3.lock ]]; then
    #upgrade sonarr v3 lock
    rm /install/.sonarrv3.lock
    touch /install/.sonarr.lock
fi