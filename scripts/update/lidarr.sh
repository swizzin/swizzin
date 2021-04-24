#!/bin/bash
if [[ -f /install/.lidarr.lock ]]; then

    #Move old homedirectory installations to opt and switch to netcore
    user=$(cut -d: -f1 < /root/.master.info)
    if [[ -d /home/$user/Lidarr ]]; then
        echo_info "Moving Lidarr instllation to opt and switching it to net-core"
        wasActive=$(systemctl is-active lidarr)
        systemctl stop lidarr

        echo_progress_start "Moving ~/Lidarr to /root/swizzin/backups/lidarr-mono"
        mkdir -p /root/swizzin/backups
        mv /home/"$user"/Lidarr /root/swizzin/backups/lidarr-mono || {
            echo_error "Move failed, please investigate. exiting."
            exit 1
        }
        echo_progress_done "Directory moved"

        echo_progress_start "Downloading netcore binaries"
        urlbase="https://lidarr.servarr.com/v1/update/develop/updatefile?os=linux&runtime=netcore"
        case "$(_os_arch)" in
            "amd64") dlurl="${urlbase}&arch=x64" ;;
            "armhf") dlurl="${urlbase}&arch=arm" ;;
            "arm64") dlurl="${urlbase}&arch=arm64" ;;
            *)
                echo_error "Arch not supported"
                exit 1
                ;;
        esac

        if ! curl "$dlurl" -L -o /tmp/lidarr.tar.gz >> "$log" 2>&1; then
            echo_error "Download failed, exiting"
            exit 1
        fi
        echo_progress_done "Binaries downloaded"

        echo_progress_start "Extracting source"
        tar xfv /tmp/lidarr.tar.gz --directory /opt/ >> $log 2>&1 || {
            echo_error "Extraction failed. Please investigate. Exiting"
            exit 1
        }
        rm -rf /tmp/lidarr.tar.gz
        chown -R "${user}": /opt/Lidarr
        echo_progress_done "Source extracted"

        chown -R "$user":"$user" /opt/Lidarr

        mkdir -p "/home/${user}/.tmp"
        chown -R "${user}": "/home/${user}/.tmp"

        sed -i "/ExecStart/c\ExecStart=/opt/Lidarr/Lidarr -nobrowser -data=/home/${user}/.config/Lidarr/" /etc/systemd/system/lidarr.service
        sed -i "/ExecStop/d" /etc/systemd/system/lidarr.service
        systemctl daemon-reload

        if [[ -f /install/.nginx.lock ]]; then
            echo_progress_start "Configuring nginx"
            bash /etc/swizzin/scripts/nginx/lidarr.sh
            systemctl reload nginx
            echo_progress_done "nginx configured"
        fi

        if [[ $wasActive = "active" ]]; then
            systemctl start lidarr
        fi
        echo_success "Lidarr moved to opt on netcore"

    fi

fi
