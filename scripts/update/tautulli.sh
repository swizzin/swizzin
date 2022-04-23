#!/bin/bash

if [[ -f /install/.tautulli.lock ]]; then
    if [[ ! -d /opt/tautulli/.git ]]; then
        systemctl stop tautulli
        chown -R tautulli:nogroup /opt/tautulli
        sudo -u tautulli git -C /opt/tautulli init
        sudo -u tautulli git -C /opt/tautulli remote add origin https://github.com/Tautulli/Tautulli.git
        sudo -u tautulli git -C /opt/tautulli fetch origin
        sudo -u tautulli git -C /opt/tautulli reset --hard origin/master
        systemctl start tautulli
    fi

    if ! grep -q python3 /etc/systemd/system/tautulli.service; then
        sed -i 's|ExecStart=.*|ExecStart=/usr/bin/python3 /opt/tautulli/Tautulli.py --quiet --daemon --nolaunch --config /opt/tautulli/config.ini --datadir /opt/tautulli|g' /etc/systemd/system/tautulli.service
        chown -R tautulli:nogroup /opt/tautulli
        sudo -u tautulli git -C /opt/tautulli pull
        systemctl daemon-reload
        systemctl try-restart tautulli
    fi
fi

if [[ -f /install/.plexpy.lock ]]; then
    # only update if plexpy is installed, otherwise use the app built-in updater

    # backup plexpy config and remove it
    active=$(systemctl is-active plexpy)
    if [[ $active == "active" ]]; then
        systemctl stop plexpy
    fi
    cp -a /opt/plexpy/config.ini /tmp/config.ini.tautulli_bak &> /dev/null
    cp -a /opt/plexpy/plexpy.db /tmp/tautulli.db.tautulli_bak &> /dev/null
    cp -a /opt/plexpy/tautulli.db /tmp/tautulli.db.tautulli_bak &> /dev/null

    systemctl stop plexpy
    systemctl disable -q plexpy
    rm -rf /opt/plexpy
    rm /install/.plexpy.lock
    rm -f /etc/nginx/apps/plexpy.conf
    systemctl reload nginx
    rm /etc/systemd/system/plexpy.service

    # install tautulli instead
    source /usr/local/bin/swizzin/install/tautulli.sh &> /dev/null
    systemctl stop tautulli

    # restore backups
    mv /tmp/config.ini.tautulli_bak /opt/tautulli/config.ini &> /dev/null
    mv /tmp/tautulli.db.tautulli_bak /opt/tautulli/tautulli.db &> /dev/null

    sed -i 's#/opt/plexpy#/opt/tautulli#g' /opt/tautulli/config.ini
    sed -i "s/http_root.*/http_root = \"tautulli\"/g" /opt/tautulli/config.ini
    chown -R tautulli:nogroup /opt/tautulli
    if [[ $active == "active" ]]; then
        systemctl enable -q --now tautulli
    fi
fi
