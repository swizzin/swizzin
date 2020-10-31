#!/bin/bash
# Temporary upgrade script for the panel until panel becomes more self-sufficient

if [[ -f /install/.panel.lock ]]; then
  if ! dpkg -s acl > /dev/null 2>&1; then
    echo_progress_start "Modifying ACLs for swizzin group to prevent panel issues"
    apt_install acl
    setfacl -m g:swizzin:rx /home/*
    echo_progress_done
  fi 
  cd /opt/swizzin/swizzin
  #git reset HEAD --hard
  echo_progress_start "Pulling new commits"
  git pull 2> /dev/null || { PANELRESET=1; }
  if [[ $PANELRESET == 1 ]]; then
    echo_warn "Working around unclean git repo"
    git fetch origin master
    cp -a core/custom core/custom.tmp
    git reset --hard origin/master
    mv core/custom.tmp/* core/custom/
    rm -r core/custom.tmp
  fi
  echo_progress_done "Commits pulled"
  echo_progress_start "Checking pip for new depends"
  if ! /opt/swizzin/venv/bin/python /opt/swizzin/swizzin/tests/test_requirements.py >> ${log} 2>&1; then
    /opt/swizzin/venv/bin/pip install -r /opt/swizzin/swizzin/requirements.txt >> ${log} 2>&1
  fi
  echo_progress_done "Depends up-to-date"
  echo_progress_start "Restarting Panel"
  systemctl restart panel
  echo_progress_done "Done!"
fi