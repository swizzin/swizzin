#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)

if [[ ! -f /.install/.sabnzbd.lock ]]; then
  echo "SABnzbd not detected. Exiting!"
  exit 1
fi

localversion=$(/home/${user}/sabnzbd/venv/bin/python /home/${user}/sabnzbd/SABnzbd.py --version | grep -m1 SABnzbd | cut -d- -f2)
latest=$(curl -s https://sabnzbd.org/downloads | grep Linux | grep download-link-src | grep -oP "href=\"\K[^\"]+")
latestversion=$(echo $latest | awk -F "/" '{print $NF}' | cut -d- -f2)

if dpkg --compare-versions ${localversion} lt ${latestversion}; then
  echo "Upgrading SABnzbd ... "
  cd /home/${user}
  wget -q -O sabnzbd.tar.gz $latest
  cp -a sabnzbd sabnzbd.old
  rm -rf sabnzbd/*
  tar xzf sabnzbd.tar.gz --strip-components=1 -C /home/${user}/sabnzbd > /dev/null 2>&1
  rm -rf sabnzbd.old
  systemctl try-restart sabnzbd
  echo "SABnzbd has been upgraded to version ${latestversion}!"
else
  echo "Nothing to do! Current version (${localversion}) matches the remote version (${latestversion})"
  exit 0
fi