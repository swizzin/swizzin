#!/bin/bash
# Temporary upgrade script for the panel until panel becomes more self-sufficient

if [[ -f /install/.panel.lock ]]; then
  cd /opt/swizzin/swizzin
  echo "Pulling new commits"
  git pull
  echo "Restarting Panel"
  systemctl restart panel
  echo "Done!"
fi