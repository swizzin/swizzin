#!/bin/bash
# radarr v3 installer
# Flying sauasges for swizzin 2020

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

#shellcheck source=sources/functions/ask
. /etc/swizzin/sources/functions/ask

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ -z $radarrv3owner ]];then
    radarrv3owner=$(_get_master_username)
fi

[[ -z $radarrv02owner ]] && radarrv02owner=$(_get_master_username)

#Handles existing v0.2 instances
_radarrv02_flow(){
    v02present=false
    if [[ -f /install/.radarr.lock ]]; then
        v02present=true
    fi

    if [[ -f /etc/systemd/system/radarr.service ]]; then
        v02present=true
    fi

    #Should match a v0.2 as those were on Mono
    if [[ -f /opt/Radarr/Radarr.exe ]]; then
        v02present=true
    fi

    # TODO check /opt?
    # if dpkg -l | grep nzbdrone > /dev/null 2>&1 ; then
    #     v02present=true
    # fi

    if [[ $v02present == "true" ]]; then
        echo
        echo "Radarr v0.2 is detected."
        echo "Continuing will migrate your current v0.2 installation. This will stop and remove radarr v0.2." | tee -a $log
        echo "You can read more about the migration at https://docs.swizzin.ltd/applications/radarrv3#migrating-from-v02"
        echo "An additional copy of the backup will be made into /root/swizzin/backups/radarrv02.bak/" | tee -a $log
        echo
        if ! ask "Do you want to continue?" N; then
            exit 0
        fi

        if ask "Would you like to trigger a Radarr-side backup?" Y; then
            echo "Backing up Radarr v0.2" | tee -a $log
            if [[ -f /install/.nginx.lock ]]; then
                address="http://127.0.0.1:7878/radarr/api"
            else
                address="http://127.0.0.1:7878/api"
            fi

            if [[ ! -d /home/"${radarrv02owner}"/.config/Radarr ]]; then
                echo "No Radarr config folder found for $radarrv02owner. Exiting" | tee -a $log
                exit 1
            fi

            apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"${radarrv02owner}"/.config/Radarr/config.xml)
            echo "apikey = $apikey" >> $log

            #This starts a backup on the current Radarr instance. The logic below waits until the query returns as "completed"
            response=$(curl -sd '{name: "backup"}' -H "Content-Type: application/json" -X POST ${address}/command?apikey="${apikey}" --insecure)
            echo "$response" >> $log
            id=$(echo "$response" | jq '.id' )
            echo "id=$id" >> $log

            if [[ -z $id ]]; then
                echo "Failure triggering backup (see logs)." | tee -a $log
                echo "We cannot trigger Radarr to dump a current backup, but the current files and previous weekly backups can still be copied" | tee -a $log
                if ! ask "Continue without triggering internal Radarr backup?" N; then
                    exit 1
                fi
            else
                echo "Radarr backup Job ID = $id, waiting to finish" >> $log

                status=""
                counter=0
                while [[ $status =~ ^(queued|started|)$ ]]; do
                    sleep 0.2
                    status=$(curl -s "${address}/command/$id?apikey=${apikey}" --insecure | jq -r '.status')
                    ((counter+=1))
                    if [[ $counter -gt 100 ]]; then
                        echo "Radarr backup took too long, cancelling installation."
                        exit 1
                    fi
                done
                if [[ $status = "completed" ]]; then 
                    echo "Backup complete"
                else
                    echo "Radarr returned unexpected status ($status). Terminating. Please try again."
                    exit 1
                fi
            fi
        fi

        mkdir -p /root/swizzin/backups/
        echo "Copying files to a backup location"
        cp -R /home/"${radarrv02owner}"/.config/Radarr /root/swizzin/backups/radarrv02.bak

        if [[ "${radarrv02owner}" != "${radarrv3owner}" ]]; then
            echo "Copying config to new owner"
            if [[ -d /home/$radarrv3owner/.config/Radarr ]]; then
                rm -rf /home/"$radarrv3owner"/.config/Radarr
            fi
            mkdir -p /home/"${radarrv3owner}"/.config
            cp -R /home/"${radarrv02owner}"/.config/Radarr /home/"$radarrv3owner"/.config/Radarr
        else
            echo "No need to migrate, users are the same" >> $log
        fi
        echo "Backups copied"
        
        systemctl stop radarr

        echo "Removing Radarr v0.2" | tee -a $log
        # shellcheck source=scripts/remove/radarr.sh
        bash /etc/swizzin/scripts/remove/radarr.sh
        
    fi
}

_install_radarrv3 () {
    apt_install curl mediainfo 
    echo "Installing Radarr v3 from sources" | tee -a $log

    radarrv3confdir="/home/$radarrv3owner/.config/Radarr"
    mkdir -p "$radarrv3confdir"
    chown -R "$radarrv3owner":"$radarrv3owner" "$radarrv3confdir"

    echo "Downloading source files"
    if ! wget "https://radarr.servarr.com/v1/update/nightly/updatefile?os=linux&runtime=netcore&arch=x64" -O /tmp/Radarrv3.tar.gz >> $log 2>&1; then
        echo "Download failed, exiting"
        exit 1
    fi
    echo "Extracting archive"
    tar -xvf /tmp/Radarrv3.tar.gz -C /opt >> $log 2>&1 

    touch /install/.radarrv3.lock

cat > /etc/systemd/system/radarr.service <<EOF
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
# Change the user and group variables here.
User=${radarrv3owner}
Group=${radarrv3owner}

Type=simple

# Change the path to Radarr or mono here if it is in a different location for you.
ExecStart=/opt/Radarr/Radarr -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# These lines optionally isolate (sandbox) Radarr from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=/opt/Radarr /path/to/movies/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now -q radarr

    sleep 1



    if [[ -f $radarrv3confdir/update_required ]]; then 
        echo "Radarr is installing an upgrade..."
        # echo "You can track the update by running \`systemctl status sonarr\` in another shell."
        # echo "In case of errors, please press CTRL+C and run \`box remove sonarrv3\` in this shell and check in with us in the Discord"
        while [[ -f $radarrv3confdir/update_required ]]; do 
            sleep 1
            # echo "still here"
            # This completed in 4 seconds on a 1vcpu 1gb ram instance on an i3-5xxx so this should really not cause infinite loops.
        done
        echo "Upgrade finished"
    fi
}


_nginx_radarrv3 () {
    if [[ -f /install/.nginx.lock ]]; then
        #TODO what is this sleep here for? See if this can be fixed by doing a check for whatever it needs to
        sleep 10
        echo "Installing nginx configuration" | tee -a $log
        bash /usr/local/bin/swizzin/nginx/radarrv3.sh
        systemctl reload nginx >> $log 2>&1
    fi
}

_radarrv02_flow
_install_radarrv3
_nginx_radarrv3


if [[ -f /install/.ombi.lock ]]; then
    echo "Please adjust your Ombi setup accordingly"
fi

if [[ -f /install/.tautulli.lock ]]; then
    echo "Please adjust your Tautulli setup accordingly"
fi

if [[ -f /install/.bazarr.lock ]]; then
    echo "Please adjust your Bazarr setup accordingly"
fi

echo "Radarr v3 installed"