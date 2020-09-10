#!/bin/bash

if [[ -f /etc/apt/sources.list.d/plexmediaserver.list ]]; then
  if grep -q "/deb/" /etc/apt/sources.list.d/plexmediaserver.list; then
      echo "Updating plex apt repo endpoint"
      echo "deb https://downloads.plex.tv/repo/deb public main" > /etc/apt/sources.list.d/plexmediaserver.list
      apt_update
  fi     
fi