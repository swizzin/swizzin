#!/bin/bash
# Install updateplex by mrworf
# https://github.com/mrworf/plexupdate

if [[ ! -f /install/.plex.lock ]]; then
  echo "Plex doesn't appear to be installed. What do you hope to accomplish by running this script?"
  exit 1
fi

if [[ ! -f /install/.updateplex.lock ]]; then
  user=$(cut -d: -f1 < /root/.master.info)
  sudo -H -u $user bash -c "$(wget -qO - https://raw.githubusercontent.com/mrworf/plexupdate/master/extras/installer.sh)"
  # In case I need this file to do more than install updateplex in the future (unlikely)
  touch /install/.updateplex.lock
fi 

# Yes that's it, get outta here you dirty club rats