#!/usr/bin/env bash

if [[ -f /install/.subsonic.lock ]]; then
    echo_warn "Subsonic support in swizzin has been discontinued, please migrate to Airsonic.\nYou can ignore this warning if you do not intend to migrate."
    echo_docs "applications/airsonic"
fi
