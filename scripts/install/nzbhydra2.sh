#!/bin/bash

echo "Downloading Subsonic dependencies and installing ... "
case $codename in
  "buster")
  echo "Adding adoptopenjdk repository"
  apt_install software-properties-common --skip-update
  wget -qO- https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key --keyring /etc/apt/trusted.gpg.d/adoptopenjdk.gpg add - >>"${OUTTO}" 2>&1
  add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ >>"${OUTTO}" 2>&1
  apt_update
  apt_install adoptopenjdk-8-hotspot
  ;;
  *)
  apt_install openjdk-8-jre
  ;;
esac
nzbhydra2usr="master"
nzbhydar2dir=/opt/nzbhydra2

    echo "Downloading latest release" | tee -a $log
    dlurl=$(curl -s https://api.github.com/repos/theotherp/nzbhydra2/releases/latest | grep -E "browser_download_url" | grep linux | head -1 | cut -d\" -f 4)
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
        echo "Failed to query github" | tee -a $log
        exit 1
    fi

    wget "${dlurl}" -O /tmp/nzbhydra2-linux.zip >> $log 2>&1
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
        echo "Failed to download binary" | tee -a $log
        exit 1
    fi

    # unzip tmpfile to nzbhydra dir

    chown -R $nzbhydra2usr:$nzbhydra2usr $nzbhydar2dir 
    chmod +x $nzbhydar2dir/nzbhydra2



cat > /etc/systemd/system/nzbhydra2.service <<EOF
[Unit]
Description=NZBHydra2 Daemon
Documentation=https://github.com/theotherp/nzbhydra2
After=network.target

[Service]
User=${nzbhydra2usr}
Group=${nzbhydra2usr}
Type=simple
# Set to the folder where you extracted the ZIP
WorkingDirectory=/home/nzbhydra/nzbhydra2


# NZBHydra stores its data in a "data" subfolder of its installation path
# To change that set the --datafolder parameter:
# --datafolder /path-to/datafolder
ExecStart=/home/nzbhydra/nzbhydra2/nzbhydra2 --nobrowser

Restart=always

[Install]
WantedBy=multi-user.target
EOF