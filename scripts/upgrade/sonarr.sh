#!/bin/bash

if [[ ! -f /install/.sonarr.lock ]]; then
  echo "Sonarr not detected. Exiting!"
  exit 1
fi

box install sonarrv3