#!/bin/bash
#
# [Quick Box :: Install Ombi (formerly Plex Request.NET) package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | liza
# URL                :   https://quickbox.io
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
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
    echo "deb http://download.mono-project.com/repo/debian wheezy main" > /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
    echo "deb http://download.mono-project.com/repo/debian wheezy-libjpeg62-compat main" >> /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
    echo "deb http://download.mono-project.com/repo/debian wheezy-apache24-compat main" >> /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
  fi

  apt-get update -q >/dev/null 2>&1
  apt-get install -q -y mono-devel mono-complete unzip >/dev/null 2>&1
}

function _install() {
  cd /opt
  curl -sL https://git.io/vKEJz | grep release | grep zip | cut -d "\"" -f 2 | sed -e 's/\/tidusjar/https:\/\/github.com\/tidusjar/g' | xargs wget --quiet -O Ombi.zip >/dev/null 2>&1
  unzip Ombi.zip >/dev/null 2>&1
  mv Release ombi
  rm Ombi.zip
  chown -R ${user}: ombi
}


function _services() {
  cp ${local_setup}templates/sysd/ombi.template /etc/systemd/system/ombi.service
  sed -i "s/USER/${user}/g" /etc/systemd/system/ombi.service
  systemctl enable ombi >/dev/null 2>&1
  systemctl start ombi
  touch /install/.ombi.lock
  cat > /etc/apache2/sites-enabled/ombi.conf <<EOF
<Location /ombi>
ProxyPass http://localhost:3000/ombi
ProxyPassReverse http://localhost:3000/ombi
Require all granted
</Location>
EOF
  chown www-data: /etc/apache2/sites-enabled/ombi.conf
  service apache2 reload
}

spinner() {
    local pid=$1
    local delay=0.25
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [${bold}${yellow}%c${normal}]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    echo -ne "${OK}"
}

OUTTO=/srv/rutorrent/home/db/output.log
local_setup=/etc/QuickBox/setup/
user=$(cat /srv/rutorrent/home/db/master.txt)

echo "Updating dependencies (this could take a bit) ... " > ${OUTTO} 2>&1
echo -en "\rUpdating dependencies ... ";_depends
echo "Installing Ombi ... " >> ${OUTTO} 2>&1
echo -en "\rInstalling Ombi ... ";_install
echo "Initializing Ombi service ... " >> ${OUTTO} 2>&1
echo -en "\rInitializing Ombi service ... ";_services
echo "Ombi Installation Complete!" >> ${OUTTO} 2>&1
echo -en "\rOmbi Installation Complete!"
  sleep 5
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;

echo ""
