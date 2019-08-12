#!/bin/bash
#Have I mentioned I hate mono?

if [[ -f /install/.sonarr.lock ]] || [[ -f /install/.radarr.lock ]] || [[ -f /install/.lidarr.lock ]]; then
  version=$(lsb_release -cs)
  distro=$(lsb_release -is)
  master=$(cut -d: -f1 < /root/.master.info)
  sonarr=$(systemctl is-active sonarr@$master)
  radarr=$(systemctl is-active radarr)
  lidarr=$(systemctl is-active lidarr)
  . /etc/swizzin/sources/functions/mono
  mono_repo_update
  for a in sonarr radarr; do
  if [[ $a = "active" ]]; then
    if [[ $a =~ ("sonarr") ]]; then
      a=$a@$master
    fi
    systemctl restart $a
  fi
  done
fi

if [[ -f /install/.sonarr.lock ]]; then
  if ! apt-key adv --list-public-keys | grep A236C58F409091A18ACA53CBEBFF6B99D9B78493; then
    version=$(lsb_release -cs)
    distribution=$(lsb_release -is)
    if [[ $distribution == "Ubuntu" ]]; then
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 >/dev/null 2>&1
    elif [[ $distribution == "Debian" ]]; then
      if [[ $version == "jessie" ]]; then
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 >/dev/null 2>&1
      else
        #buster friendly
        apt-key --keyring /etc/apt/trusted.gpg.d/nzbdrone.gpg adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493
      fi
    fi
  fi
fi