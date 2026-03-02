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

    
    echo_log_only "Checking if transmission ports are open if nginx is installed"
    ran='false'
    for user in $(_get_user_list); do
        confpath="/home/${user}/.config/transmission-daemon/settings.json"
        if jq '.["rpc-bind-address"]' "$confpath" | grep -q '0.0.0.0'; then
            if [ -f /install/.nginx.log ]; then
                if [[ "${ran}" == "false" ]]; then
                    echo_info "Closing open un-proxied ports for transmission daemons"
                fi
                ran='true'
                isActive=$(systemctl is-active transmission@"${user}")
                if [[ $isActive == "active" ]]; then
                    systemctl stop transmission@"${user}"
                fi
                
                jq '.["rpc-bind-address"] = "127.0.0.1"' "$confpath" >> "${confpath}.tmp"
                mv "${confpath}.tmp" "$confpath"

                if [[ $isActive == "active" ]]; then
                    systemctl start transmission@"${user}"
                fi
            fi
        fi
    done
    if [[ "${ran}" == "true" ]]; then
        echo_warn "Please ensure that your existing connections to transmission work, specifically from systems not running on this host.\n
        In case you encounter any issues, please consult this guide:\n
        https://swizzin.ltd/applications/transmission/#connecting-to-transmission-remote"
    fi

fi
