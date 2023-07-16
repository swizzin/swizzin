#!/bin/bash
# Update sickrage to sickchill

if [[ -f /install/.sickrage.lock ]]; then
    echo_progress_start "Updating SickRage to SickChill"
    user=$(cut -d: -f1 < /root/.master.info)
    active=$(systemctl is-active sickrage@$user)
    if [[ $active == 'active' ]]; then
        systemctl disable -q --now sickrage@$user
    fi
    cd /home/$user
    git clone https://github.com/SickChill/SickChill.git .sickchill
    chown -R $user: .sickchill
    cp -a .sickrage/config.ini .sickchill
    cp -a .sickrage/sickbeard.db .sickchill
    sed -i "s|git_remote_url.*|git_remote_url = https://github.com/SickChill/SickChill.git|g" /home/${master}/.sickchill/config.ini
    echo_warn "Moving ~/.sickrage to ~/sickrage.defunct. You can safely delete this yourself if the upgrade completes successfully."
    mv .sickrage sickrage.defunct
    rm -f /etc/systemd/system/sickrage@.service
    cat > /etc/systemd/system/sickchill@.service << SSS
[Unit]
Description=SickChill
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=%I
Group=%I
ExecStart=/usr/bin/python /home/%I/.sickchill/SickBeard.py -q --daemon --nolaunch --datadir=/home/%I/.sickchill


[Install]
WantedBy=multi-user.target
SSS
    if [[ -f /install/.nginx.lock ]]; then
        rm -f /etc/nginx/apps/sickrage.conf
        cat > /etc/nginx/apps/sickchill.conf << SRC
location /sickchill {
    include /etc/nginx/snippets/proxy.conf;
    proxy_pass        http://127.0.0.1:8081/sickchill;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${master};
}
SRC
        sed -i "s/web_root.*/web_root = \/sickchill/g" /home/${master}/.sickchill/config.ini
        systemctl reload nginx
    fi
    systemctl daemon-reload
    if [[ $active == 'active' ]]; then
        systemctl start sickchill@$master
    fi
    mv /install/.sickrage.lock /install/.sickchill.lock
    echo_progress_done
fi

if [[ -f /install/.sickchill.lock ]]; then
    if [[ -f /etc/systemd/system/sickchill@.service ]] || [[ -f /opt/.venv/sickchill/bin/python2 ]]; then
        . /etc/swizzin/sources/functions/pyenv
        . /etc/swizzin/sources/functions/utils
        user=$(_get_master_username)
        if [[ -f /etc/systemd/system/sickchill@.service ]]; then
            active=$(systemctl is-active sickchill@$user)
            unit=sickchill@${user}
        else
            active=$(systemctl is-active sickchill)
            unit=sickchill
        fi
        systemctl disable -q --now ${unit} >> ${log} 2>&1
        rm_if_exists /opt/.venv/sickchill
        LIST='git python3-dev python3-venv python3-pip'
        apt_install $LIST
        python3 -m venv /opt/.venv/sickchill

        chown -R ${user}: /opt/.venv/sickchill

        echo_progress_start "Updating SickChill ..."
        if [[ -d /home/${user}/.sickchill ]]; then
            mv /home/${user}/.sickchill /opt/sickchill
        fi
        sudo -u ${user} bash -c "cd /opt/sickchill; git pull" >> $log 2>&1
        # echo "Installing requirements.txt with pip ..."
        sudo -u ${user} bash -c "/opt/.venv/sickchill/bin/pip3 install -r /opt/sickchill/requirements.txt" >> $log 2>&1

        cat > /etc/systemd/system/sickchill.service << SCSD
[Unit]
Description=SickChill
After=syslog.target network.target

[Service]
Type=forking
GuessMainPID=no
User=${user}
Group=${user}
ExecStart=/opt/.venv/sickchill/bin/python3 /opt/sickchill/SickChill.py -q --daemon --nolaunch --datadir=/opt/sickchill

[Install]
WantedBy=multi-user.target
SCSD
        systemctl daemon-reload
        rm_if_exists /etc/systemd/system/sickchill@.service
        if [[ $active == "active" ]]; then
            systemctl enable -q --now sickchill 2>&1 | tee -a $log
        fi
        echo_progress_done
    fi
fi
