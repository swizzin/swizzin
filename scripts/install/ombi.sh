#!/bin/bash
#
# Ombi installer
#
# Author:   QuickBox.IO | liara
# Ported for swizzin by liara
#
# QuickBox Copyright (C) 2016
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

function _depends() {
  if [[ ! -f /etc/apt/sources.list.d/mono-xamarin.list ]]; then
    if [[ $distribution == "Ubuntu" ]]; then
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
    elif [[ $distribution == "Debian" ]]; then
      if [[ $version == "jessie" ]]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
      else
        gpg --keyserver http://keyserver.ubuntu.com --recv 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
        gpg --export 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF > /etc/apt/trusted.gpg.d/mono-xamarin.gpg
      fi
    fi
    echo "deb http://download.mono-project.com/repo/debian wheezy/snapshots/4.8 main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
  fi
}

function _install() {
  apt-get update -q  >/dev/null 2>&1
  apt-get install -q -y mono-devel mono-complete unzip screen >/dev/null 2>&1
  cd /opt
  #curl -sL https://git.io/vKEJz | grep release | grep zip | cut -d "\"" -f 2 | sed -e 's/\/tidusjar/https:\/\/github.com\/tidusjar/g' | xargs wget --quiet -O Ombi.zip >/dev/null 2>&1
  wget -q -O Ombi.zip https://github.com/tidusjar/Ombi/releases/download/v2.2.1/Ombi.zip
  unzip Ombi.zip >/dev/null 2>&1
  mv Release ombi
  rm Ombi.zip
  chown -R ${user}: ombi
}


function _services() {
cat > /etc/systemd/system/ombi.service <<OMB
Description=Systemd script to run Ombi as a service
After=network-online.target

[Service]
User=${user}
Group=${user}
Type=forking
ExecStart=/usr/bin/screen -f -a -d -m -S ombi mono /opt/ombi/Ombi.exe -p 3000 --base ombi
ExecStop=-/bin/kill -HUP
WorkingDirectory=/home/${user}/

[Install]
WantedBy=multi-user.target
OMB
  systemctl enable ombi >/dev/null 2>&1
  systemctl start ombi
  touch /install/.ombi.lock
  if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/ombi.sh
    service nginx reload
  fi
}


if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  OUTTO="/srv/panel/db/output.log"
else
  OUTTO="/dev/null"
fi
distribution=$(lsb_release -is)
version=$(lsb_release -cs)
user=$(cat /root/.master.info | cut -d: -f1)

echo -en "\rUpdating dependencies ... ";_depends
echo -en "\rInstalling Ombi ... ";_install
echo -en "\rInitializing Ombi service ... ";_services
echo -en "\rOmbi Installation Complete!"
