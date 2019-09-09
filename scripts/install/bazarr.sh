#!/bin/bash
# Bazarr installation
# Author: liara
# Copyright (C) 2019 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

user=$(cut -d: -f1 < /root/.master.info )
apt-get -y -q install python-pip > /dev/null 2>&1
cd /home/${user}
echo "Cloning into '/home/${user}/bazarr'"
git clone https://github.com/morpheus65535/bazarr.git > /dev/null 2>&1
chown -R ${user}: bazarr
cd bazarr
echo "Checking python depends"
sudo -u ${user} bash -c "pip install --user -r requirements.txt" > /dev/null 2>&1
mkdir -p /home/${user}/bazarr/data/config/


if [[ -f /install/.sonarr.lock ]]; then
  sonarrapi=$(grep -oP "ApiKey>\K[^<]+" /home/${user}/.config/NzbDrone/config.xml)
  sonarrport=$(grep -oP "\<Port>\K[^<]+" /home/${user}/.config/NzbDrone/config.xml)
  sonarrbase=$(grep -oP "UrlBase>\K[^<]+" /home/${user}/.config/NzbDrone/config.xml)

  cat >> /home/${user}/bazarr/data/config/config.ini <<SONC
[sonarr]
apikey = ${sonarrapi} 
full_update = Daily
ip = 127.0.0.1
only_monitored = False
base_url = /${sonarrbase}
ssl = False
port = ${sonarrport}
SONC
fi

if [[ -f /install/.radarr.lock ]]; then
  radarrapi=$(grep -oP "ApiKey>\K[^<]+" /home/${user}/.config/Radarr/config.xml)
  radarrport=$(grep -oP "\<Port>\K[^<]+" /home/${user}/.config/Radarr/config.xml)
  radarrbase=$(grep -oP "UrlBase>\K[^<]+" /home/${user}/.config/Radarr/config.xml)

  cat >> /home/${user}/bazarr/data/config/config.ini <<RADC

[radarr]
apikey = ${radarrapi}
full_update = Daily
ip = 127.0.0.1
only_monitored = False
base_url = /${radarrbase}
ssl = False
port = ${radarrport}
RADC
fi

if [[ -f /install/.nginx.lock ]]; then
  sleep 10
  bash /usr/local/bin/swizzin/nginx/bazarr.sh
  service nginx reload
  echo "Please ensure during bazarr wizard that baseurl is set to: /bazarr/"
else
  cat >> /home/${user}/bazarr/data/config/config.ini <<BAZC

[general]
ip = 0.0.0.0
base_url = /
BAZC
fi

if [[ -f /install/.sonarr.lock ]]; then
    echo "use_sonarr = True" >> /home/${user}/bazarr/data/config/config.ini
else
    echo "use_sonarr = False" >> /home/${user}/bazarr/data/config/config.ini
fi

if [[ -f /install/.radarr.lock ]]; then
    echo "use_radarr = True" >> /home/${user}/bazarr/data/config/config.ini
else
    echo "use_radarr = False" >> /home/${user}/bazarr/data/config/config.ini
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

chown -R ${user}: /home/${user}/bazarr

systemctl enable --now bazarr

#curl 'http://127.0.0.1:6767/bazarr/save_wizard' --data 'settings_general_ip=127.0.0.1&settings_general_port=6767&settings_general_baseurl=%2Fbazarr%2F&settings_general_sourcepath=&settings_general_destpath=&settings_general_sourcepath=&settings_general_destpath=&settings_general_sourcepath=&settings_general_destpath=&settings_general_sourcepath=&settings_general_destpath=&settings_general_sourcepath=&settings_general_destpath=&settings_general_sourcepath_movie=&settings_general_destpath_movie=&settings_general_sourcepath_movie=&settings_general_destpath_movie=&settings_general_sourcepath_movie=&settings_general_destpath_movie=&settings_general_sourcepath_movie=&settings_general_destpath_movie=&settings_general_sourcepath_movie=&settings_general_destpath_movie=&settings_subfolder=current&settings_subfolder_custom=&settings_addic7ed_username=&settings_addic7ed_password=&settings_addic7ed_random_agents=on&settings_assrt_token=&settings_betaseries_token=&settings_legendastv_username=&settings_legendastv_password=&settings_napisy24_username=&settings_napisy24_password=&settings_opensubtitles_username=&settings_opensubtitles_password=&settings_subscene_username=&settings_subscene_password=&settings_xsubs_username=&settings_xsubs_password=&settings_subliminal_providers=&settings_subliminal_languages=en&settings_serie_default_forced=False&settings_movie_default_forced=False&settings_sonarr_ip=127.0.0.1&settings_sonarr_port=8989&settings_sonarr_baseurl=%2Fsonarr&settings_sonarr_apikey=${sonarrapi}&settings_radarr_ip=127.0.0.1&settings_radarr_port=7878&settings_radarr_baseurl=%2Fradarr&settings_radarr_apikey=${radarrapi}'

touch /install/.bazarr.lock