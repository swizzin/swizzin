#!/bin/bash
# Audiobookshelf

__remove_audiobookshelf() {
    echo_progress_start "Removing audiobookshelf apt sources"
    systemctl stop audiobookshelf.service
    sysctl disable audiobookshelf.service
    apt remove audiobookshelf
    rm -f /etc/apt/sources.list.d/audiobookshelf.list
    apt update
    apt autoremove
    rm -f /opt/swizzin/static/img/apps/audiobookshelf.png
}

__remove_from_pannel() {
    content= 'from core.profiles import *\n\n'
    echo -e "$content" > /opt/swizzin/core/custom/profiles.py
}

__remove_audiobookshelf
__remove_from_pannel
