#!/bin/bash
# Calibre installer

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [ -z "$CALIBRE_LIBRARY_USER" ]; then
    CALIBRE_LIBRARY_USER=$(_get_master_username)
fi

if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
    CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
fi

_install() {
    apt_install xdg-utils wget xz-utils libxcb-xinerama0 libfontconfig libgl1-mesa-glx
    # TODO make a whiptail to let user install from repo, binaries, or source, and modify that selection based on the arch
    echo_progress_start "Installing calibre"
    if [[ $(_os_arch) = "amd64" ]]; then
        wget https://download.calibre-ebook.com/linux-installer.sh -O /tmp/calibre-installer.sh >> $log 2>&1
        if ! bash /tmp/calibre-installer.sh install_dir=/opt >> $log 2>&1; then
            echo_error "failed to install calibre"
            exit 1
        fi
    else
        echo_info "Calibre needs to be built from source for $(_os_arch). We are falling back onto apt for the time being\nRun box upgrade calibre to upgrade at a later stage"
        apt_install calibre
        # : #TODO build calibre from source
    fi
    echo_progress_done "Calibre installed"
}

_library() {
    if [ -e "$CALIBRE_LIBRARY_PATH" ]; then
        echo_info "Calibre library already exists"
        return 0
    fi

    if [ "$CALIBRE_LIBRARY_SKIP" = "true" ]; then
        echo_info "Library creation skipped."
        return 0
    fi

    echo_progress_start "Creating library"

    # Need to start a library with a book so might as well get some good ass literature here
    wget https://www.gutenberg.org/ebooks/59112.epub.images -O /tmp/rur.epub >> $log 2>&1
    wget https://www.gutenberg.org/ebooks/7849.epub.noimages -O /tmp/trial.epub >> $log 2>&1

    mkdir -p "$CALIBRE_LIBRARY_PATH"
    calibredb add /tmp/rur.epub /tmp/trial.epub --with-library "$CALIBRE_LIBRARY_PATH"/ >> $log
    chown -R "$CALIBRE_LIBRARY_USER":"$CALIBRE_LIBRARY_USER" "$CALIBRE_LIBRARY_PATH" -R
    chmod 0770 -R "$CALIBRE_LIBRARY_PATH"
    echo_progress_done "Library installed to $CALIBRE_LIBRARY_PATH"
}

_install
_library
# _content_server
echo_info "You can install calibreweb or calibrecs separately"
echo_docs "application/calibreweb"
echo_docs "application/calibrecs"

touch /install/.calibre.lock
echo_success "Calibre installed"
