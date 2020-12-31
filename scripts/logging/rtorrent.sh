#!/usr/bin/env bash

# commands+=('rtorrent')
paths+=("/home/$loguser/.rtorrent.rc")
commands+=("dpkg -s rtorrent")
version="$(rtorrent -h | head -1 | awk '{print $NF}')"
