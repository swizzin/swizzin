#!/bin/bash
# Jackett updater script

if [[ -f /install/.jackett.lock ]]; then
    username=$(cut -d: -f1 < /root/.master.info)
    active=$(systemctl is-active jackett@$username)

    if grep -q "ExecStart=/usr/bin/mono" /etc/systemd/system/jackett@.service; then
        echo_progress_start "Updating Jackett from mono"
        jackettver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | grep -v repository | awk -F "[><]" '{print $3}')
        sed -i 's|ExecStart.*|ExecStart=/bin/sh -c "/home/%I/Jackett/jackett_launcher.sh"|g' /etc/systemd/system/jackett@.service
        systemctl daemon-reload
        if [[ $active == "active" ]]; then
            systemctl stop jackett@$username
        fi
        rm -rf /home/$username/Jackett
        cd /home/$username
        wget -q https://github.com/Jackett/Jackett/releases/download/$jackettver/Jackett.Binaries.LinuxAMDx64.tar.gz
        tar -xvzf Jackett.Binaries.LinuxAMDx64.tar.gz > /dev/null 2>&1
        rm -f Jackett.Binaries.LinuxAMDx64.tar.gz
        chown ${username}:${username} -R Jackett
        if [[ $active == "active" ]]; then
            restartjackett=1
        fi
    else
        :
    fi

    if ! grep -q "jackett_launcher" /etc/systemd/system/jackett@.service; then
        cat > /etc/systemd/system/jackett@.service << JAK
[Unit]
Description=jackett for %I
After=network.target

[Service]
SyslogIdentifier=jackett.%I
Type=simple
User=%I
WorkingDirectory=/home/%I/Jackett
ExecStart=/bin/sh -c "/home/%I/Jackett/jackett_launcher.sh"
Restart=always
RestartSec=5
TimeoutStopSec=20
[Install]
WantedBy=multi-user.target
JAK

        sleep 1
        systemctl daemon-reload

        if [[ $active == "active" ]]; then
            restartjackett=1
        fi
        echo_progress_done
    fi

    if [[ ! -f /home/${username}/Jackett/jackett_launcher.sh ]]; then
        echo_progress_start "Creating Jackett launcher script"
        cat > /home/${username}/Jackett/jackett_launcher.sh << 'JL'
#!/bin/bash
user=$(whoami)

/home/${user}/Jackett/jackett

while pgrep -u ${user} JackettUpdater > /dev/null ; do
     sleep 1
done

echo "Jackett update complete"
JL

        chmod +x /home/${username}/Jackett/jackett_launcher.sh

        if [[ $active == "active" ]]; then
            restartjackett=1
        fi
        echo_progress_done
    fi

    if [[ -f /install/.nginx.lock ]]; then
        if grep -q "proxy_set_header" /etc/nginx/apps/jackett.conf; then
            echo_progress_start "Updating Jackett nginx config"
            sed -i "/proxy_set_header/d" /etc/nginx/apps/jackett.conf
            systemctl reload nginx
            echo_progress_done
        fi

    fi

    if [[ $(stat -c %U /home/${username}/.config/Jackett/ServerConfig.json) == "root" ]]; then
        echo_progress_start "Fixing Jackett permissions"
        chown -R ${username}: /home/${username}/.config/Jackett
        echo_progress_done
    fi

    if [[ $restartjackett == 1 ]]; then
        echo_progress_start "Restarting Jackett"
        systemctl restart jackett@${username}
        echo_progress_done
    fi
fi
