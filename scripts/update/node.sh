#!/bin/bash
# Node update check
# author: liara
. /etc/swizzin/sources/functions/npm
if [[ -f /etc/apt/sources.list.d/nodesource.listE ]]; then mv /etc/apt/sources.list.d/nodesource.listE /etc/apt/sources.list.d/nodesource.list; fi
npm_update
