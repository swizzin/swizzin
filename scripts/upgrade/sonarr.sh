#!/bin/bash

if [[ ! -f /install/.sonarr.lock ]]; then
  echo_error "Sonarr not detected. Exiting!"
  exit 1
fi

box install sonarrv3