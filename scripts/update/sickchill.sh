#!/bin/bash
# Update sickrage to sickchill

if [[ -f /install/.sickrage.lock ]]; then
    echo "Updating SickRage to SickChill"
    master=$(cat /root/.master.info | cut -d: -f1)
    active=$(systemctl is-active sickrage@$master)
    if [[ $active == 'active' ]]; then
        systemctl disable --now sickrage@$master
    fi
    cd /home/$master
    git clone https://github.com/SickChill/SickChill.git .sickchill
    chown -R $master: .sickchill
    cp -a .sickrage/config.ini .sickchill
    cp -a .sickrage/sickbeard.db .sickchill
    sed -i "s|git_remote_url.*|git_remote_url = https://github.com/SickChill/SickChill.git|g" /home/${master}/.sickchill/config.ini
    echo "Moving ~/.sickrage to ~/sickrage.defunct. You can safely delete this yourself if the upgrade completes successfully."
    mv .sickrage sickrage.defunct
    rm -f /etc/systemd/system/sickrage@.service
    cat > /etc/systemd/system/sickchill@.service <<SSS
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
        cat > /etc/nginx/apps/sickchill.conf <<SRC
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
fi


