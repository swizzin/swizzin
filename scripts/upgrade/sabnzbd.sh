#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)

if [[ ! -f /install/.sabnzbd.lock ]]; then
    echo_error "SABnzbd not detected. Exiting!"
    exit 1
fi

. /etc/swizzin/sources/functions/pyenv
localversion=$(/opt/.venv/sabnzbd/bin/python /opt/sabnzbd/SABnzbd.py --version | grep -m1 SABnzbd | cut -d- -f2)
#latest=$(curl -s https://sabnzbd.org/downloads | grep -m1 Linux | grep download-link-src | grep -oP "href=\"\K[^\"]+")
latest=$(curl -sL https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest | jq -r '.assets[]?.browser_download_url | select(contains("tar.gz"))') || {
    echo_error "Failed to query GitHub for latest sabnzbd version"
    exit 1
}
latestversion=$(echo $latest | awk -F "/" '{print $NF}' | cut -d- -f2)
pyvenv_version=$(/opt/.venv/sabnzbd/bin/python --version | awk '{print $2}')

if dpkg --compare-versions ${pyvenv_version} lt 3.6.0 && dpkg --compare-versions ${latestversion} ge 3.2.0; then
    LIST='par2 p7zip-full libffi-dev libssl-dev libglib2.0-dev libdbus-1-dev'
    PYENV_REBUILD=True
elif [[ -f /opt/.venv/sabnzbd/bin/python2 ]]; then
    LIST='par2 p7zip-full python3-dev python3-setuptools python3-pip python3-venv libffi-dev libssl-dev libglib2.0-dev libdbus-1-dev'
    PYENV_REBUILD=True
else
    LIST='par2 p7zip-full python3-dev python3-setuptools python3-pip python3-venv libffi-dev libssl-dev libglib2.0-dev libdbus-1-dev'
fi
apt_install $LIST

if dpkg --compare-versions ${localversion} lt ${latestversion}; then
    if [[ $PYENV_REBUILD == True ]]; then
        echo_progress_start "Upgrading SABnzbd python virtual environment"
        rm -rf /opt/.venv/sabnzbd
        systempy3_ver=$(get_candidate_version python3)
        if dpkg --compare-versions ${systempy3_ver} lt 3.6.0; then
            pyenv_install
            pyenv_install_version 3.7.7
            pyenv_create_venv 3.7.7 /opt/.venv/sabnzbd
            chown -R ${user}: /opt/.venv/sabnzbd
        else
            python3_venv ${user} sabnzbd
        fi
        if grep -q python2 /etc/systemd/system/sabnzbd.service; then
            sed -i 's/python2/python/g' /etc/systemd/system/sabnzbd.service
            systemctl daemon-reload
        fi

        echo_progress_done
    fi
    echo_progress_start "Downloading latest source"
    wget -q -O /tmp/sabnzbd.tar.gz "$latest"
    rm -rf /opt/sabnzbd
    mkdir -p /opt/sabnzbd
    tar xzf /tmp/sabnzbd.tar.gz --strip-components=1 -C /opt/sabnzbd >> "$log" 2>&1
    chown -R ${user}: /opt/sabnzbd
    echo_progress_done
    if [[ -f /opt/.venv/sabnzbd/bin/python2 ]]; then
        echo_progress_start "Upgrading SABnzbd python virtual environment to python3"
        rm -rf /opt/.venv/sabnzbd
        systempy3_ver=$(get_candidate_version python3)
        if dpkg --compare-versions ${systempy3_ver} lt 3.6.0; then
            pyenv_install
            pyenv_install_version 3.7.7
            pyenv_create_venv 3.7.7 /opt/.venv/sabnzbd
            chown -R ${user}: /opt/.venv/sabnzbd
        else
            python3_venv ${user} sabnzbd
        fi
        if grep -q python2 /etc/systemd/system/sabnzbd.service; then
            sed -i 's/python2/python/g' /etc/systemd/system/sabnzbd.service
            systemctl daemon-reload
        fi
        sudo -u ${user} bash -c "/opt/.venv/sabnzbd/bin/pip install --upgrade pip wheel" >> "${log}" 2>&1
        sudo -u ${user} bash -c "/opt/.venv/sabnzbd/bin/pip install -r /opt/sabnzbd/requirements.txt" >> "$log" 2>&1
        echo_progress_done
    fi
    rm /tmp/sabnzbd.tar.gz

    echo_progress_start "Checking pip requirements"
    if [[ $latestversion =~ ^3\.0\.[1-2] ]]; then
        sed -i "s/feedparser.*/feedparser<6.0.0/g" /opt/sabnzbd/requirements.txt
    fi
    sudo -u ${user} bash -c "/opt/.venv/sabnzbd/bin/pip install -r /opt/sabnzbd/requirements.txt" >> "$log" 2>&1
    echo_progress_done
    systemctl try-restart sabnzbd
    echo_info "SABnzbd has been upgraded to version ${latestversion}!"
else
    echo_info "Nothing to do! Current version (${localversion}) matches the remote version (${latestversion})"
    exit 0
fi
