# Sonarr v3 installer
# Flying sauasges for swizzin 2020

#Handles existing v2 instances
_sonarrv2_flow(){

    v2present=false
    if [[ -f /install/.sonarr.lock ]]; then 
        v2present=true
    fi
    if dpkg -l | grep nzbdrone > /dev/null 2>&1 ; then 
        v2present=true
    fi

    if [[ $v2present == "true" ]]; then 
        echo "Sonarr v2 is detected. Continuing will upgrade your current installation."
        echo "An additional copy of the backup will be made into /root/sonarrv2.bak/"
        #shellcheck source=sources/functions/ask
        . /etc/swizzin/sources/functions/ask

        if ! ask "Do you want to continue?" N; then
            exit 0
        fi

        # TODO make backup
        # TODO 
        echo "Backing up Sonarr v2 (takes minimum 2 minutes)"

        address="http://localhost:8989/sonarr/api"
        master=$(cut -d: -f1 < /root/.master.info)
        apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/${master}/.config/NzbDrone/config.xml)
        id=$(curl -sd '{name: "backup"}' -H "Content-Type: application/json" -X POST ${address}/command?apikey=${apikey} | jq '.id' )
        echo "Job ID = $id, waiting to finish"

        status=""
        while [[ $status != "\"completed\"" ]]; do 
            status=$(curl -s "${address}/command/$id?apikey=${apikey}" | jq '.status')
        done
        cp -R /home/${master}/.config/NzbDrone /root/sonarrv2.bak
        echo "Backup completed"

        # rm /install/.sonarr.lock
    fi
}

_setup_apt_sonarrv3 () {
    codename=$(lsb_release -cs)
    distribution=$(lsb_release -is)

    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
    echo "deb https://apt.sonarr.tv/${distribution,,} ${codename,,} main" | sudo tee /etc/apt/sources.list.d/sonarr.list

    #shellcheck source=sources/functions/mono
    . /etc/swizzin/sources/functions/mono
    mono_repo_setup

    apt-get update
}

_install_sonarrv3 () {
    # https://github.com/Sonarr/Sonarr/blob/phantom-develop/distribution/debian/config

    master=$(cut -d: -f1 < /root/.master.info)
    echo "sonarr/owning_user ${master}" | debconf-set-selections
    echo "sonarr/owning_group ${master}" | debconf-set-selections
    DEBIAN_FRONTEND=non-interactive apt-get install -yq sonarr
}

if [[ -f /install/.ombi.lock ]]; then
    echo "Please adjust your Ombi setup accordingly"
fi

_sonarrv2_flow
_setup_apt_sonarrv3
# _install_sonarrv3