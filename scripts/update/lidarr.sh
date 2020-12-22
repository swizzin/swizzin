#!/bin/bash
if [[ -f /install/.lidarr.lock ]]; then

    #Move old homedirectory installations to opt
    user=$(cut -d: -f1 < /root/.master.info)
    if [[ -d /home/$user/Lidarr ]]; then
        echo_info "Moving Lidarr instllation to opt"
        wasActive=$(systemctl is-active lidarr)
        systemctl stop lidarr

        mv /home/$user/Lidarr /opt/Lidarr
        sudo chown -R $user:$user /opt/Lidarr

        sed -i "/ExecStart/c\ExecStart=/usr/bin/mono /opt/Lidarr/Lidarr.exe -nobrowser" /etc/systemd/system/lidarr.service
        systemctl daemon-reload

        if [[ $wasActive = "active" ]]; then
            systemctl start lidarr
        fi
    fi
fi
