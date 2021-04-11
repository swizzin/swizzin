#!/bin/bash
if [[ -f /install/.lidarr.lock ]]; then

    #Move old homedirectory installations to opt and switch to netcore
    user=$(cut -d: -f1 < /root/.master.info)
    if [[ -d /home/$user/Lidarr ]]; then
        echo_info "Moving Lidarr instllation to opt and switching it to net-core"
        wasActive=$(systemctl is-active lidarr)
        systemctl stop lidarr

        mv /home/"$user"/Lidarr /opt/Lidarr

        echo_progress_start "Downloading source files"
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
        echo_progress_done "Source downloaded"

        echo_progress_start "Extracting source"
        tar xfv /tmp/lidarr.tar.gz --directory /opt/ >> $log 2>&1
        rm -rf /tmp/lidarr.tar.gz
        chown -R "${user}": /opt/Lidarr
        echo_progress_done "Source extracted"

        sudo chown -R "$user":"$user" /opt/Lidarr

        sed -i "/ExecStart/c\ExecStart=/opt/Lidarr/Lidarr -nobrowser -data=/home/${user}/.config/Lidarr/" /etc/systemd/system/lidarr.service
        sed -i "/ExecStop/d" /etc/systemd/system/lidarr.service
        systemctl daemon-reload

        if [[ $wasActive = "active" ]]; then
            systemctl start lidarr
        fi

    fi

fi
