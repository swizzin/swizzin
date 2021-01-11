#!/usr/bin/env bash

case "$(os_arch)" in
    amd64)
        wget https://download.calibre-ebook.com/linux-installer.sh -O /tmp/calibre-installer.sh >> $log 2>&1
        if ! bash /tmp/calibre-installer.sh install_dir=/opt >> $log 2>&1; then
            echo_error "failed to install calibre"
            exit 1
        fi
        ;;
    *)
        echo_info "No upgrader yet! Your installation is currently managed by apt. Please use that in the meantime"
        ;;
esac
