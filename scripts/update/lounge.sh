#!/bin/bash

function _uplounge() {
    active=$(systemctl is-active lounge)

    if [[ $active == "active" ]]; then
        systemctl stop lounge
    fi
    npm install -g thelounge@latest >> /dev/null 2>&1
    sudo -u lounge bash -c "thelounge install thelounge-theme-zenburn" >> /dev/null 2>&1
    if [[ ! -d /home/lounge/.thelounge ]]; then
        mv /home/lounge/.lounge /home/lounge/.thelounge
        sed -i 's|theme: "zenburn"|theme: "thelounge-theme-zenburn"|g' /home/lounge/.thelounge/config.js
    fi
    if [[ $active == "active" ]]; then
        systemctl start lounge
    fi
}

if [[ -f /install/.lounge.lock ]]; then
    if grep -q "/usr/bin/lounge" /etc/systemd/system/lounge.service; then
        sed -i "s/ExecStart=\/usr\/bin\/lounge/ExecStart=\/usr\/bin\/thelounge/g" /etc/systemd/system/lounge.service
        systemctl daemon-reload
    fi

    if grep -q 'bind: "127.0.0.1"' /home/lounge/.thelounge/config.js; then
        sed -i 's/bind: "127.0.0.1",/bind: undefined,/g' /home/lounge/.thelounge/config.js
        sed -i 's/host: undefined,/host: "127.0.0.1",/g' /home/lounge/.thelounge/config.js
        systemctl try-restart lounge
    fi

    if [[ $(thelounge -v) =~ "v2" ]]; then
        if ask "Lounge has an update available. Upgrade?" Y; then
            _uplounge
        fi
    fi
    if [ -e /home/lounge ]; then
        active=$(systemctl is-active lounge)

        if [[ $active == "active" ]]; then
            systemctl stop lounge
        fi

        ####### after this change all configs will always be under the /opt/lounge dir, so make sure to target those only.
        ####### ONLY ADD NEW CHANGES BELOW THIS LINE, NOTHING ABOVE CAN BE CHANGED NO MO
        mv /home/lounge /opt/lounge
        usermod -d /opt/lounge lounge
        chown -R lounge: /opt/lounge

        if [[ $active == "active" ]]; then
            systemctl start lounge
        fi
    fi

fi
