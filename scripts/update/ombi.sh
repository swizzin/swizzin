#!/bin/bash
if [[ -f /install/.ombi.lock ]]; then
    # Change ombi service to stock one
    if [[ -f /etc/systemd/system/ombi.service ]]; then
        echo_progress_start "Moving ombi back to stock service file"
        systemctl cat ombi >> $log 2>&1
        if systemctl is-active ombi -q; then
            ombiwasactive=true
            systemctl -q stop ombi
        fi
        rm /etc/systemd/system/ombi.service
        mkdir -p /etc/systemd/system/ombi.service.d
        cat > /etc/systemd/system/ombi.service.d/override.conf << CONF
[Service]
ExecStart=
ExecStart=/opt/Ombi/Ombi --host http://0.0.0.0:3000 --storage /etc/Ombi
CONF
        systemctl daemon-reload
        systemctl cat ombi >> $log 2>&1

        if [[ -f /install/.nginx.lock ]]; then
            bash /etc/swizzin/scripts/nginx/ombi.sh
            systemctl reload nginx
        fi

        if [[ $ombiwasactive = "true" ]]; then
            systemctl start ombi
        fi
        if [[ -L /etc/systemd/system/multi-user.target.wants/ombi.service && ! -e /etc/systemd/system/multi-user.target.wants/ombi.service ]]; then
            systemctl enable -q ombi >> $log 2>&1
            echo_info "Fixing Ombi systemd symlinks"
        fi
        echo_progress_done "Ombi reset back to stock service"
    fi
fi
