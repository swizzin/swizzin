#!/bin/bash
#
# [Quick Box :: Install Subsonic package]
#
# QUICKLAB REPOS
# QuickLab _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi
MASTER=$(cut -d: -f1 < /root/.master.info)


echo "Creating subsonic-tmp install directory ... " >>"${OUTTO}" 2>&1;
mkdir /root/subsonic-tmp

echo "Downloading Subsonic dependencies and installing ... " >>"${OUTTO}" 2>&1;
apt-get -y install openjdk-8-jre
current=$(wget -qO- http://www.subsonic.org/pages/download.jsp | grep -m1 .deb | cut -d'"' -f2)
latest=$(wget -qO- http://www.subsonic.org/pages/$current | grep -m1 .deb | cut -d'"' -f2)
wget -O /root/subsonic-tmp/subsonic.deb $latest || { echo "Could not download Subsonic. Exiting."; exit 1; }
cd /root/subsonic-tmp
dpkg -i subsonic.deb

touch /install/.subsonic.lock

echo "Removing subsonic-tmp install directory ... " >>"${OUTTO}" 2>&1;
cd
rm -rf /root/subsonic-tmp

echo "Modifying Subsonic startup script ... " >>"${OUTTO}" 2>&1;
cat > /usr/share/subsonic/subsonic.sh <<SUBS
#!/bin/sh
MASTER=$(cut -d: -f1 < /root/.master.info )
SUBSONICIP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

SUBSONIC_HOME=/srv/subsonic
SUBSONIC_HOST=0.0.0.0
SUBSONIC_PORT=4040
SUBSONIC_HTTPS_PORT=0
SUBSONIC_CONTEXT_PATH=/
SUBSONIC_MAX_MEMORY=200
SUBSONIC_PIDFILE=
SUBSONIC_DEFAULT_MUSIC_FOLDER=/home/\$MASTER/Music
SUBSONIC_DEFAULT_PODCAST_FOLDER=/home/\$MASTER/Podcast
SUBSONIC_DEFAULT_PLAYLIST_FOLDER=/home/\$MASTER/Playlists

quiet=0
# Use JAVA_HOME if set, otherwise assume java is in the path.
JAVA=java
if [ -e "\${JAVA_HOME}" ]
    then
    JAVA=\${JAVA_HOME}/bin/java
fi

# Create Subsonic home directory.
mkdir -p \${SUBSONIC_HOME}
LOG=\${SUBSONIC_HOME}/subsonic_sh.log
rm -f \${LOG}

cd \$(dirname \$0)
if [ -L \$0 ] && ([ -e /bin/readlink ] || [ -e /usr/bin/readlink ]); then
    cd \$(dirname \$(readlink \$0))
fi

\${JAVA} -Xmx\${SUBSONIC_MAX_MEMORY}m \
  -Dsubsonic.home=\${SUBSONIC_HOME} \
  -Dsubsonic.host=\${SUBSONIC_HOST} \
  -Dsubsonic.port=\${SUBSONIC_PORT} \
  -Dsubsonic.httpsPort=\${SUBSONIC_HTTPS_PORT} \
  -Dsubsonic.contextPath=\${SUBSONIC_CONTEXT_PATH} \
  -Dsubsonic.defaultMusicFolder=\${SUBSONIC_DEFAULT_MUSIC_FOLDER} \
  -Dsubsonic.defaultPodcastFolder=\${SUBSONIC_DEFAULT_PODCAST_FOLDER} \
  -Dsubsonic.defaultPlaylistFolder=\${SUBSONIC_DEFAULT_PLAYLIST_FOLDER} \
  -Djava.awt.headless=true \
  -verbose:gc \
  -jar subsonic-booter-jar-with-dependencies.jar > \${LOG} 2>&1
SUBS

echo "Enabling Subsonic Systemd configuration" >>"${OUTTO}" 2>&1;
service stop subsonic >/dev/null 2>&1
cat > /etc/systemd/system/subsonic.service <<SUBSD
[Unit]
Description=Subsonic Sound-Server

[Service]
User=${MASTER}
Group=${MASTER}
WorkingDirectory=/srv/subsonic
ExecStart=/usr/share/subsonic/subsonic.sh
Restart=on-abort
ExecStop=-/bin/kill -HUP
PIDFile=/var/run/subsonic.pid

[Install]
WantedBy=multi-user.target
SUBSD

mkdir /srv/subsonic
chown ${MASTER}: /srv/subsonic
systemctl enable subsonic.service >/dev/null 2>&1
systemctl start subsonic.service >/dev/null 2>&1

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/subsonic.sh
  service nginx reload
fi

echo "Subsonic Install Complete!" >>"${OUTTO}" 2>&1;
sleep 2
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
