#!/bin/bash

if [[ ! -f /install/.radarr.lock ]]; then
  echo "Radarr not detected. Exiting!"
  exit 1
fi

box install radarrv3