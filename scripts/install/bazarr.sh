#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info )
apt-get -y -q install python-pip > /dev/null 2>&1
cd /home/${user}
echo "Cloning into 'bazarr'"
git clone https://github.com/morpheus65535/bazarr.git > /dev/null 2>&1
chown -R ${user}: bazarr
cd bazarr
echo "Checking python depends"
sudo -u ${user} bash -c "pip install --user -r requirements.txt" > /dev/null 2>&1

if [[ -f /install/.sonarr.lock ]]; then
api=$(grep "Api" /home/${user}/.config/NzbDrone/config.xml | cut -d\> -f2 | cut -d\< -f1)
appport=$(grep "\<Port" /home/${user}/.config/NzbDrone/config.xml | cut -d\> -f2 | cut -d\< -f1)
cat >> /home/${user}/bazarr/data/config/config.ini <<SONC
[sonarr]
apikey = ${api} 
full_update = Daily
ip = 127.0.0.1
only_monitored = False
base_url = /sonarr
ssl = False
port = ${appport}
SONC
fi

if [[ -f /install/.radarr.lock ]]; then
api=$(grep "Api" /home/${user}/.config/Radarr/config.xml | cut -d\> -f2 | cut -d\< -f1)
appport=$(grep "\<Port" /home/${user}/.config/Radarr/config.xml | cut -d\> -f2 | cut -d\< -f1)
cat >> /home/${user}/bazarr/data/config/config.ini <<RADC

[radarr]
apikey = ${api}
full_update = Daily
ip = 127.0.0.1
only_monitored = False
base_url = /radarr
ssl = False
port = ${appport}
RADC
fi

cat >> /home/${user}/bazarr/data/config/config.ini <<BAZC

[general]
ip = 0.0.0.0
base_url =
BAZC

if [[ -f /install/.sonarr.lock ]]; then
echo "use_sonarr = True" >> /home/${user}/bazarr/data/config/config.ini
fi

if [[ -f /install/.radarr.lock ]]; then
echo "use_radarr = True" >> /home/${user}/bazarr/data/config/config.ini
fi

chown -R ${user}: /home/${user}/bazarr

if [[ -f /install/.nginx.lock ]]; then
    sleep 10
    bash /usr/local/bin/swizzin/nginx/bazarr.sh
    service nginx reload
fi

cat > /etc/systemd/system/bazarr.service <<BAZ
[Unit]
Description=Bazarr for ${user}
After=syslog.target network.target

[Service]
WorkingDirectory=/home/${user}/bazarr
User=${user}
Group=${user}
UMask=0002
Restart=on-failure
RestartSec=5
Type=simple
ExecStart=/usr/bin/python /home/${user}/bazarr/bazarr.py
KillSignal=SIGINT
TimeoutStopSec=20
SyslogIdentifier=bazarr.${user}

[Install]
WantedBy=multi-user.target
BAZ

systemctl enable --now bazarr

touch /install/.bazarr.lock