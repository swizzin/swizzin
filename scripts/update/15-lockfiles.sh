#!/usr/bin/env bash

# Added 31 Dec 2020
# Move lockfiles from old directory to whatever the new one ends up being lol
# should run once and only once
if [[ -d /install/ ]]; then
    readarray -t list_installed < <(find /install -type f -name ".*.lock" | awk -F. '{print $2}')
    echo_log_only "Moving ${list_installed[*]} to  "
    for app in "${list_installed[@]}"; do
        mkdir -p "$lockdir"
        mv /install/."$app".lock "$lockdir"/"$app"
    done
    rm -rf /install/ # byyeeeee
fi
