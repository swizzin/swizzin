#!/usr/bin/env bash

paths+=(/home/"$master"/.config/Lidarr/logs/Lidarr.txt)
paths+=(/home/"$master"/.config/Lidarr/logs/Lidarr.{0..2}.txt)
paths+=(/home/"$master"/.config/Lidarr/logs/Lidarr.debug.txt)
paths+=(/home/"$master"/.config/Lidarr/logs/Lidarr.trace.txt)
commands+=(journalctl -u lidarr)
