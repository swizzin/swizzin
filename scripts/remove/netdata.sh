#! /bin/bash
# Netdata uninstaller for swizzin

/usr/libexec/netdata/netdata-uninstaller.sh --yes --env /etc/netdata/.environment -f >> $log 2>&1 || {
    echo_error "Netdata remover failed!"
    exit 1
}

rm -rf /install/.netdata.lock
