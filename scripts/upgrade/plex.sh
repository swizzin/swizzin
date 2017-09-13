#!/bin/bash
# Install updateplex by mrworf
# https://github.com/mrworf/plexupdate

if [[ ! -f /install/.updateplex.lock ]]; then
  bash -c "$(wget -qO - https://raw.githubusercontent.com/mrworf/plexupdate/master/extras/installer.sh)"
  # In case I need this file to do more than install updateplex in the future (unlikely)
  touch /install/.updateplex.lock
fi 

# Yes that's it, get outta here you dirty club rats