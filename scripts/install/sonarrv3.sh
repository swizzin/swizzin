#!/bin/bash
# Sonarr v3 installer
# Flying sauasges for swizzin 2020

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

[[ -z $sonarrv2owner ]] && sonarrv2owner=$(_get_master_username)

if [[ -z $sonarrv3owner ]]; then
    sonarrv3owner=$(_get_master_username)
fi

sonarrv3confdir="/home/$sonarrv3owner/.config/sonarr"

#Handles existing v2 instances
_sonarrv2_flow() {
    v2present=false
    if [[ -f /install/.sonarr.lock ]]; then
        v2present=true
    fi
    if dpkg -l | grep nzbdrone > /dev/null 2>&1; then
        v2present=true
    fi

    if [[ $v2present == "true" ]]; then
        echo_warn "Sonarr v2 is detected. Continuing will migrate your current v2 installation. This will stop and remove sonarr v2 You can read more about the migration at https://swizzin.ltd/applications/sonarrv3#migrating-from-v2. An additional copy of the backup will be made into /root/swizzin/backups/sonarrv2.bak/"
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

            [[ -z $sonarrv2owner ]] && sonarrv2owner=$(_get_master_username)
            if [[ ! -d /home/"${sonarrv2owner}"/.config/NzbDrone ]]; then
                echo_error "No Sonarr config folder found for $sonarrv2owner. Exiting"
                exit 1
            fi

            apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"${sonarrv2owner}"/.config/NzbDrone/config.xml)
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
        cp -R /home/"${sonarrv2owner}"/.config/NzbDrone /root/swizzin/backups/sonarrv2.bak
        echo_progress_done "Backups copied"

        if [[ -d /home/"${sonarrv3owner}"/.config/sonarr ]]; then
            if ask "$sonarrv3owner already has a sonarrv3 directory. Overwrite?" Y; then
                rm -rf
                cp -R /home/"${sonarrv2owner}"/.config/NzbDrone /home/"${sonarrv3owner}"/.config/sonarr
            else
                echo_info "Leaving v3 dir as is, why did we do any of this..."
            fi
        else
            cp -R /home/"${sonarrv2owner}"/.config/NzbDrone /home/"${sonarrv3owner}"/.config/sonarr
        fi

        systemctl stop sonarr@"${sonarrv2owner}"

        # We don't have the debconf configuration yet so we can't migrate the data.
        # Instead we symlink so postinst knows where it's at.
        if [ -f "/usr/lib/sonarr/nzbdrone-appdata" ]; then
            rm "/usr/lib/sonarr/nzbdrone-appdata"
        else
            mkdir -p "/usr/lib/sonarr"
        fi

        echo_progress_start "Removing Sonarr v2"
        # shellcheck source=scripts/remove/sonarr.sh
        bash /etc/swizzin/scripts/remove/sonarr.sh
        echo_progress_done
    fi
}

_add_sonarr_repos() {
    echo_progress_start "Adding apt sources for Sonarr v3"
    codename=$(lsb_release -cs)
    distribution=$(lsb_release -is)

    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8 >> $log 2>&1
    echo "deb https://apt.sonarr.tv/${distribution,,} ${codename,,} main" | tee /etc/apt/sources.list.d/sonarr.list >> $log 2>&1

    #shellcheck source=sources/functions/mono
    . /etc/swizzin/sources/functions/mono
    mono_repo_setup

    apt_update

    if ! apt-cache policy sonarr | grep -q apt.sonarr.tv; then
        echo_error "Sonarr was not found from apt.sonarr.tv repository. Please inspect the logs and try again later."
        exit 1
    fi
}

_install_sonarrv3() {
    mkdir -p "$sonarrv3confdir"
    chown -R "$sonarrv3owner":"$sonarrv3owner" /home/$sonarrv3owner/.config

    echo_log_only "Setting sonarr v3 owner to $sonarrv3owner"
    # settings relevant from https://github.com/Sonarr/Sonarr/blob/phantom-develop/distribution/debian/config
    echo "sonarr sonarr/owning_user string ${sonarrv3owner}" | debconf-set-selections
    echo "sonarr sonarr/owning_group string ${sonarrv3owner}" | debconf-set-selections
    echo "sonarr sonarr/config_directory string ${sonarrv3confdir}" | debconf-set-selections
    apt_install sonarr sqlite3
    touch /install/.sonarrv3.lock
    sleep 1

    if [[ ! -d /usr/lib/sonarr ]]; then
        echo_error "The Sonarr v3 pacakge did not install correctly. Please try again. (Is sonarr repo reachable?)"
        exit 1
    fi

    if [[ -f $sonarrv3confdir/update_required ]]; then
        echo_progress_start "Sonarr is installing an internal upgrade..."
        # echo "You can track the update by running \`systemctl status sonarr\` in another shell."
        # echo "In case of errors, please press CTRL+C and run \`box remove sonarrv3\` in this shell and check in with us in the Discord"
        while [[ -f $sonarrv3confdir/update_required ]]; do
            sleep 1
            # This completed in 4 seconds on a 1vcpu 1gb ram instance on an i3-5xxx so this should really not cause infinite loops.
        done
        echo_progress_done "Internal upgrade finished"
    fi
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
        sleep 10
        bash /usr/local/bin/swizzin/nginx/sonarrv3.sh
        systemctl reload nginx >> $log 2>&1
        echo_progress_done
    fi
}

_sonarrv2_flow
_add_sonarr_repos
_install_sonarrv3
_nginx_sonarr

touch /install/.sonarrv3.lock

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
