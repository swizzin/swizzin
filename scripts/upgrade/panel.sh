#!/bin/bash
# Temporary upgrade script for the panel until panel becomes more self-sufficient

if [[ -f /install/.panel.lock ]]; then
  if ! dpkg -s acl > /dev/null 2>&1; then
    echo "Modifying ACLs for swizzin group to prevent panel issues"
    apt-get -y -q install acl
    setfacl -m g:swizzin:rx /home/*
  fi 
  cd /opt/swizzin/swizzin
  echo "Resetting git repo"
  git reset HEAD --hard
  echo "Pulling new commits"
  git pull
  echo "Restarting Panel"
  systemctl restart panel
  echo "Done!"
fi