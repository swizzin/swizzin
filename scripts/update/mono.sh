#!/bin/bash
#Have I mentioned I hate mono?

if [[ -f /install/.sonarr.lock ]] || [[ -f /install/.radarr.lock ]] || [[ -f /install/.lidarr.lock ]]; then
  version=$(lsb_release -cs)
  distro=$(lsb_release -is)
  master=$(cat /root/.master.info | cut -d : -f1)
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