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



__add_to_pannel(){
curl -o  /opt/swizzin/static/img/apps/audiobookshelf.png https://www.audiobookshelf.org/Logo.png
# Content to write
content='from core.profiles import *\n\n
class audiobookshelf_meta:\n
    name = "audiobookshelf"\n
    pretty_name = "Audiobookshelf"\n
    baseurl = "/audiobookshelf"\n
    systemd = "audiobookshelf"\n
    check_theD = True'

# Write content to the file
echo -e "$content" > /opt/swizzin/core/custom/profiles.py

echo "Content has been written to /opt/swizzin/core/custom/profiles.py"
touch /install/.audiobookshelf.lock
systemctl restart panel
}

_install_audiobookshelf
__add_to_pannel
