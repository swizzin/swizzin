#!/usr/bin/env bash

paths+=(/home/"$master"/.config/Radarr/logs/radarr.txt)
paths+=(/home/"$master"/.config/Radarr/logs/radarr.{0..2}.txt)
paths+=(/home/"$master"/.config/Radarr/logs/radarr.debug.txt)
paths+=(/home/"$master"/.config/Radarr/logs/radarr.trace.txt)
commands+=(journalctl -u radarr)
