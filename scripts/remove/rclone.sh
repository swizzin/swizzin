#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
active=$(systemctl status rclone@* | grep -m1 .service | awk '{print $2}')
if [[ -n $active ]]; then
    systemctl disable --now $active
fi
rm_if_exists /usr/bin/rclone
rm_if_exists /usr/sbin/rclone
rm_if_exists /etc/systemd/system/rclone@.service
rm_if_exists /usr/local/share/man/man1/rclone.1
rm -f /install/.rclone.lock
