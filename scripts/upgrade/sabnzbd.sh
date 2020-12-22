#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)

if [[ ! -f /install/.sabnzbd.lock ]]; then
    echo_error "SABnzbd not detected. Exiting!"
    exit 1
fi

localversion=$(/opt/.venv/sabnzbd/bin/python /opt/sabnzbd/SABnzbd.py --version | grep -m1 SABnzbd | cut -d- -f2)
#latest=$(curl -s https://sabnzbd.org/downloads | grep -m1 Linux | grep download-link-src | grep -oP "href=\"\K[^\"]+")
latest=$(curl -sL https://api.github.com/repos/sabnzbd/sabnzbd/releases/latest | grep -Po '(?<="browser_download_url":).*?[^\\].tar.gz"' | sed 's/"//g')
latestversion=$(echo $latest | awk -F "/" '{print $NF}' | cut -d- -f2)

LIST='par2 p7zip-full python3-dev python3-setuptools python3-pip python3-venv libffi-dev libssl-dev libglib2.0-dev libdbus-1-dev'
apt_install $LIST

if dpkg --compare-versions ${localversion} lt ${latestversion}; then
    # echo "Upgrading SABnzbd ... "
    cd /opt/
    echo_progress_start "Downloading latest source"
    wget -q -O sabnzbd.tar.gz $latest
    rm -rf sabnzbd/*
    sudo -u ${user} bash -c "tar xzf sabnzbd.tar.gz --strip-components=1 -C /opt/sabnzbd" >> "$log" 2>&1
    echo_progress_done
    if [[ -f /opt/.venv/sabnzbd/bin/python2 ]]; then
        echo_progress_start "Upgrading SABnzbd python virtual environment to python3"
        rm -rf /opt/.venv/sabnzbd
        sudo -u ${user} bash -c "python3 -m venv /opt/.venv/sabnzbd/" >> "$log" 2>&1
        if [[ $latestversion =~ ^3\.0\.[1-2] ]]; then
            sed -i "s/feedparser.*/feedparser<6.0.0/g" /opt/sabnzbd/requirements.txt
        fi
        sudo -u ${user} bash -c "/opt/.venv/sabnzbd/bin/pip install -r /opt/sabnzbd/requirements.txt" >> "$log" 2>&1
        echo_progress_done
    fi
    rm sabnzbd.tar.gz
    sed -i 's/python2/python/g' /etc/systemd/system/sabnzbd.service
    systemctl daemon-reload
    systemctl try-restart sabnzbd
    echo_info "SABnzbd has been upgraded to version ${latestversion}!"
else
    echo_info "Nothing to do! Current version (${localversion}) matches the remote version (${latestversion})"
    exit 0
fi
