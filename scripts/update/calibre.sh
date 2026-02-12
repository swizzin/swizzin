#!/bin/bash
if [[ -f /install/.calibre.lock ]]; then
    # check if libxcb-cursor0 is installed
    if ! check_installed libxcb-cursor0; then
        echo_info "Installing new calibre dependencies"
        apt_install libxcb-cursor0
    fi
fi
