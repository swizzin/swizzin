#!/bin/bash
# Updater for jfa-go
if [[ -f /install/.jfago.lock ]]; then
    # If installed as root user, move to /opt/jfago
    if [[ -d /root/.config/jfa-go ]]; then
        echo_progress_start "jfa-go install is running as root! Moving to unprivileged user."
        # Store if the service was active before starting
        isactive=$(systemctl is-active jfago)
        echo_log_only "jfago was $isactive"
        [[ $isactive == "active" ]] && systemctl stop jfago -q

        useradd -r jfago -s /usr/sbin/nologin > /dev/null 2>&1
        mkdir -p /opt/jfago/
        mv /root/.config/jfa-go/ /opt/jfago/config
        chown jfago: /opt/jfago -R

        cat > /etc/systemd/system/jfago.service << EOF
[Unit]
Description=An account management system for Jellyfin.
After=network.target
[Service]
ExecStart=/usr/local/bin/jfa-go -config  /opt/jfago/config/config.ini -data /opt/jfago/config/
User=jfago

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        [[ $isactive == "active" ]] && systemctl start jfago -q
        echo_progress_done
    fi
fi
