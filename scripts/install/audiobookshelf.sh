#!/bin/bash
# Audiobookshelf installer

_install_audiobookshelf() {
    echo_progress_start "Installing audiobookshelf apt sources"
    apt install gnupg curl
    curl -s https://advplyr.github.io/audiobookshelf-ppa/KEY.gpg |  apt-key add -
    curl -s -o /etc/apt/sources.list.d/audiobookshelf.list https://advplyr.github.io/audiobookshelf-ppa/audiobookshelf.list
    apt update
    apt install audiobookshelf
    systemctl restart audiobookshelf.service
}

_install_audiobookshelf
