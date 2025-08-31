#!/bin/bash
if [[ -f /install/.calibre.lock ]]; then
    # check if libxcb-cursor0 is installed
    if ! check_installed libxcb-cursor0; then
        echo_info "Installing new calibre dependencies"
        apt_install libxcb-cursor0
    fi
fi

if check_installed calibre; then
    echo_info "Moving calibre to the online installer instead of the apt install"

    echo_progress_start "Removing apt-based calibre binaries"
    apt_remove calibre
    echo_progress_done

    echo_progress_start "Installing calibre from web installer"
    wget https://download.calibre-ebook.com/linux-installer.sh -O /tmp/calibre-installer.sh >> $log 2>&1
    if ! bash /tmp/calibre-installer.sh install_dir=/opt >> $log 2>&1; then
        echo_error "Failed to install calibre from web installer, please investigate and try again"
        exit 1
    fi
    echo_progress_done

fi
