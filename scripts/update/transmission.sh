#!/bin/bash

if [ -f /install/.transmission.lock ]; then

    if ! grep -q "\-\-logfile" /etc/systemd/system/transmission@.service; then
        echo_progress_start "Moving transmission's logs to a file instead of syslog"
        sed "s|ExecStart=.*|ExecStart=/usr/bin/transmission-daemon -f --log-error --logfile /home/%i/.config/transmission-daemon/transmission.log|g" -i /etc/systemd/system/transmission@.service
        systemctl daemon-reload
        readarray -t users < <(_get_user_list)
        for user in "${users[@]}"; do
            systemctl restart transmission@"$user"
        done
        echo_progress_done "Logs moved for all users"
    fi
fi
