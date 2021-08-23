#!/bin/bash
# Sonarr v3 installer
# Flying sauasges for swizzin 2020

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

[[ -z $sonarroldowner ]] && sonarroldowner=$(_get_master_username)

if [[ -z $sonarrv3owner ]]; then
    sonarrv3owner=$(_get_master_username)
fi

sonarrv3confdir="/home/$sonarrv3owner/.config/Sonarr"

#Handles existing v2 instances
_sonarrold_flow() {
    v2present=false
    if [[ -f /install/.sonarrold.lock ]]; then
        v2present=true
    fi
    if dpkg -l | grep nzbdrone > /dev/null 2>&1; then
        v2present=true
    fi

    if [[ $v2present == "true" ]]; then
        echo_warn "Sonarr v2 is detected. Continuing will migrate your current v2 installation. This will stop and remove sonarr v2 You can read more about the migration at https://swizzin.ltd/applications/sonarrv3#migrating-from-v2. An additional copy of the backup will be made into /root/swizzin/backups/sonarrold.bak/"
        if ! ask "Do you want to continue?" N; then
            exit 0
        fi

        if ask "Would you like to trigger a Sonarr-side backup?" Y; then
            echo_progress_start "Backing up Sonarr v2"
            if [[ -f /install/.nginx.lock ]]; then
                address="http://127.0.0.1:8989/sonarr/api"
            else
                address="http://127.0.0.1:8989/api"
            fi

            [[ -z $sonarroldowner ]] && sonarroldowner=$(_get_master_username)
            if [[ ! -d /home/"${sonarroldowner}"/.config/NzbDrone ]]; then
                echo_error "No Sonarr config folder found for $sonarroldowner. Exiting"
                exit 1
            fi

            apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"${sonarroldowner}"/.config/NzbDrone/config.xml)
            echo_log_only "apikey = $apikey"

            #This starts a backup on the current Sonarr instance. The logic below waits until the query returns as "completed"
            response=$(curl -sd '{name: "backup"}' -H "Content-Type: application/json" -X POST ${address}/command?apikey="${apikey}" --insecure)
            echo_log_only "$response"
            id=$(echo "$response" | jq '.id')
            echo_log_only "id=$id"

            if [[ -z $id ]]; then
                echo_warn "Failure triggering backup (see logs). Current Sonarr config and previous weekly backups will be backed up up and copied for migration"
                if ! ask "Continue without triggering internal Sonarr backup?" N; then
                    exit 1
                fi
            else
                echo_log_only "Sonarr backup Job ID = $id, waiting to finish"

                status=""
                counter=0
                while [[ $status =~ ^(queued|started|)$ ]]; do
                    sleep 0.2
                    status=$(curl -s "${address}/command/$id?apikey=${apikey}" --insecure | jq -r '.status')
                    ((counter += 1))
                    if [[ $counter -gt 100 ]]; then
                        echo_error "Sonarr backup timed out (20s), cancelling installation."
                        exit 1
                    fi
                done
                if [[ $status = "completed" ]]; then
                    echo_progress_done "Backup complete"
                else
                    echo_error "Sonarr returned unexpected status ($status). Terminating. Please try again."
                    exit 1
                fi
            fi
        fi

        mkdir -p /root/swizzin/backups/
        echo_progress_start "Copying files to a backup location"
        cp -R /home/"${sonarroldowner}"/.config/NzbDrone /root/swizzin/backups/sonarrold.bak
        echo_progress_done "Backups copied"

        if [[ -d /home/"${sonarrv3owner}"/.config/Sonarr ]]; then
            if ask "$sonarrv3owner already has a sonarrv3 directory. Overwrite?" Y; then
                rm -rf
                cp -R /home/"${sonarroldowner}"/.config/NzbDrone /home/"${sonarrv3owner}"/.config/Sonarr
            else
                echo_info "Leaving v3 dir as is, why did we do any of this..."
            fi
        else
            cp -R /home/"${sonarroldowner}"/.config/NzbDrone /home/"${sonarrv3owner}"/.config/Sonarr
        fi

        systemctl stop sonarr@"${sonarroldowner}"

        # We don't have the debconf configuration yet so we can't migrate the data.
        # Instead we symlink so postinst knows where it's at.
        if [ -f "/usr/lib/sonarr/nzbdrone-appdata" ]; then
            rm "/usr/lib/sonarr/nzbdrone-appdata"
        else
            mkdir -p "/usr/lib/sonarr"
        fi

        echo_progress_start "Removing Sonarr v2"
        # shellcheck source=scripts/remove/sonarrold.sh
        bash /etc/swizzin/scripts/remove/sonarrold.sh
        echo_progress_done
    fi
}

_install_sonarr() {
    #shellcheck source=sources/functions/mono
    . /etc/swizzin/sources/functions/mono
    mono_repo_setup
    mkdir -p "$sonarrv3confdir"
    chown -R "$sonarrv3owner":"$sonarrv3owner" /home/"$sonarrv3owner"/.config

    echo_log_only "Setting sonarr v3 owner to $sonarrv3owner"
    wget -O /tmp/sonarr.tar.gz "https://services.sonarr.tv/v1/download/main/latest?version=3&os=linux" >> ${log} 2>&1 || {
        echo_error "Sonarr could not be downloaded from sonarr.tv. Exiting"
        exit 1
    }
    tar xf /tmp/sonarr.tar.gz -C /opt >> ${log} 2>&1 || {
        echo_error "Failed to extract archive"
        exit 1
    }
    rm -f /tmp/sonarr.tar.gz
    chown -R "$sonarrv3owner":"$sonarrv3owner" /opt/Sonarr

    LIST='mono-runtime
        ca-certificates-mono
        libmono-system-net-http4.0-cil
        libmono-corlib4.5-cil
        libmono-microsoft-csharp4.0-cil
        libmono-posix4.0-cil
        libmono-system-componentmodel-dataannotations4.0-cil
        libmono-system-configuration-install4.0-cil
        libmono-system-configuration4.0-cil
        libmono-system-core4.0-cil
        libmono-system-data-datasetextensions4.0-cil
        libmono-system-data4.0-cil
        libmono-system-identitymodel4.0-cil
        libmono-system-io-compression4.0-cil
        libmono-system-numerics4.0-cil
        libmono-system-runtime-serialization4.0-cil
        libmono-system-security4.0-cil
        libmono-system-servicemodel4.0a-cil
        libmono-system-serviceprocess4.0-cil
        libmono-system-transactions4.0-cil
        libmono-system-web4.0-cil
        libmono-system-xml-linq4.0-cil
        libmono-system-xml4.0-cil
        libmono-system4.0-cil
        sqlite3
        mediainfo'

    apt_install ${LIST}

    cat > /etc/systemd/system/sonarr.service << EOSD
[Unit]
Description=Sonarr Daemon
After=network.target

[Service]
User=${sonarrv3owner}
Group=${sonarrv3owner}
UMask=0002

Type=simple
ExecStart=/usr/bin/mono --debug /opt/Sonarr/Sonarr.exe -nobrowser -data=${sonarrv3confdir}
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOSD

    if [[ ! -f ${sonarrv3confdir}/config.xml ]]; then
        cat > ${sonarrv3confdir}/config.xml << EOSC
<Config>
  <LogLevel>info</LogLevel>
  <EnableSsl>False</EnableSsl>
  <Port>8989</Port>
  <SslPort>9898</SslPort>
  <UrlBase></UrlBase>
  <BindAddress>*</BindAddress>
  <AuthenticationMethod>None</AuthenticationMethod>
  <UpdateMechanism>BuiltIn</UpdateMechanism>
  <Branch>main</Branch>
</Config>
EOSC
        chown -R ${sonarrv3owner}: ${sonarrv3confdir}/config.xml
    fi
    systemctl enable --now sonarr >> ${log} 2>&1

    touch /install/.sonarr.lock
}

# _add2usergroups_sonarrv3 () {
#         if [[ -z $sonarrv3grouplist ]]; then
#             if ask "Do you want to let Sonarr access other users' home directories?" N; then
#                 echo "Space separated list of users to give sonarr access to: (e.g. \"user1 user2\")"
#                 read -r sonarrv3grouplist
#             fi
#         fi
#         if [[ -n $sonarrv3grouplist ]]; then
#             for u in $sonarrv3grouplist; do
#                 echo "Adding ${sonarrv3owner} to $u's group"
#                 usermod -a -G "$u" "$sonarrv3owner"
#                 chmod g+rwx /home/"$u"
#             done
#         fi
# }

_nginx_sonarr() {
    if [[ -f /install/.nginx.lock ]]; then
        #TODO what is this sleep here for? See if this can be fixed by doing a check for whatever it needs to
        echo_progress_start "Installing nginx configuration"
        bash /usr/local/bin/swizzin/nginx/sonarr.sh
        systemctl reload nginx >> "$log" 2>&1
        echo_progress_done
    else
        echo_info "Sonarr will run on port 8989"
    fi
}

_sonarrold_flow
_install_sonarr
_nginx_sonarr

touch /install/.sonarr.lock

if [[ -f /install/.ombi.lock ]]; then
    echo_info "Please adjust your Ombi setup accordingly"
fi

if [[ -f /install/.tautulli.lock ]]; then
    echo_info "Please adjust your Tautulli setup accordingly"
fi

if [[ -f /install/.bazarr.lock ]]; then
    echo_info "Please adjust your Bazarr setup accordingly"
fi

echo_success "Sonarr v3 installed"
