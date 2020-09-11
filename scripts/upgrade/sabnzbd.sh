#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)

if [[ ! -f /install/.sabnzbd.lock ]]; then
  echo "SABnzbd not detected. Exiting!"
  exit 1
fi

localversion=$(/opt/.venv/sabnzbd/bin/python /opt/sabnzbd/SABnzbd.py --version | grep -m1 SABnzbd | cut -d- -f2)
latest=$(curl -s https://sabnzbd.org/downloads | grep Linux | grep download-link-src | grep -oP "href=\"\K[^\"]+")
latestversion=$(echo $latest | awk -F "/" '{print $NF}' | cut -d- -f2)

if dpkg --compare-versions ${localversion} lt ${latestversion}; then
  echo "Upgrading SABnzbd ... "
  cd /opt/
  wget -q -O sabnzbd.tar.gz $latest
  rm -rf sabnzbd/*
  sudo -u ${user} bash -c "tar xzf sabnzbd.tar.gz --strip-components=1 -C /opt/sabnzbd" > /dev/null 2>&1
  if [[ -f /opt/.venv/sabnzbd/bin/python2 ]]; then
    echo "Upgrading SABnzbd python virtual environment to python3"
    rm -rf /opt/.venv/sabnzbd
    sudo -u ${user} bash -c "python3 -m venv /opt/.venv/sabnzbd/" > /dev/null 2>&1
    sudo -u ${user} bash -c "/opt/.venv/sabnzbd/bin/pip install -r /opt/sabnzbd/requirements.txt" > /dev/null 2>&1
  fi
  rm sabnzbd.tar.gz
  sed -i 's/python2/python/g' /etc/systemd/system/sabnzbd.service
  systemctl daemon-reload
  systemctl try-restart sabnzbd
  echo "SABnzbd has been upgraded to version ${latestversion}!"
else
  echo "Nothing to do! Current version (${localversion}) matches the remote version (${latestversion})"
  exit 0
fi