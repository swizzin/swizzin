#!/bin/bash
#Have I mentioned I hate mono?

if [[ -f /install/.sonarr.lock ]] || [[ -f /install/.radarr.lock ]]; then
  version=$(lsb_release -cs)
  distro=$(lsb_release -is)
  master=$(cat /root/.master.info | cut -d : -f1)
  sonarr=$(systemctl is-active sonarr@$master)
  radarr=$(systemctl is-active radarr)
if [[ -f /etc/apt/sources.list.d/mono-xamarin.list ]]; then
  if grep -q "5.18" /etc/apt/sources.list.d/mono-xamarin.list; then
    :
  else
    echo "deb https://download.mono-project.com/repo/${distro,,} ${version}/snapshots/5.18/. main" > /etc/apt/sources.list.d/mono-xamarin.list
    echo "Upgrading to mono 5.18 snapshot"
    
    fuckmono=()

    #for i in ${PACKAGES[@]}; do
    #  fuckmono+=(${i}/${version})
    #done

    apt-get -y -q update
    apt-get -y -q upgrade
    #apt-get install -q -y --allow-downgrades ${fuckmono[@]} || apt-get install -q -y --force-yes ${fuckmono[@]}
    apt-get -y -q autoremove
  fi
else
  if [[ $distro == "Ubuntu" ]]; then
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
  elif [[ $distro == "Debian" ]]; then
    if [[ $version == "jessie" ]]; then
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
      cd /tmp
      wget -q -O libjpeg8.deb http://ftp.fr.debian.org/debian/pool/main/libj/libjpeg8/libjpeg8_8d-1+deb7u1_amd64.deb
      dpkg -i libjpeg8.deb >/dev/null 2>&1
    else
      gpg --keyserver http://keyserver.ubuntu.com --recv 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
      gpg --export 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF > /etc/apt/trusted.gpg.d/mono-xamarin.gpg
    fi
  fi
  echo "Upgrading to mono snapshot v5.18"
  echo "deb https://download.mono-project.com/repo/${distro,,} ${version}/snapshots/5.18/. main" > /etc/apt/sources.list.d/mono-xamarin.list
  apt-get -y -q update
  apt-get -y -q install mono-complete
  apt-get -y -q upgrade
fi
  for a in sonarr radarr; do
  if [[ $a = "active" ]]; then
    if [[ $a =~ ("sonarr") ]]; then
      a=$a@$master
    fi
    systemctl restart $a
  fi
  done
fi