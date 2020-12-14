#!/bin/bash
# Privatebin CLI installer, dependency for sysinfo

#shellcheck source=sources/functions/npm
. /etc/swizzin/sources/functions/npm
npm_install

echo_progress_start "Installing Privatebin CLI"
npm install --quiet --silent -g @pixelfactory/privatebin >> "$log"
echo_progress_done "Privatebin CLI installed"
