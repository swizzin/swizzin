#!/bin/bash
# QuickBox dashboard installer for Swizzin
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
if [[ ! -f /install/.nginx.lock ]]; then
  echo "ERROR: Web server not detected. Please install nginx and restart panel install."
  exit 1
fi

bash /usr/local/bin/swizzin/nginx/panel.sh
touch /install/.panel.lock
