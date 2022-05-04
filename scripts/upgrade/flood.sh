#!/bin/bash
# Flood Upgrade Script
# Author: liara

readarray -t users < <(_get_user_list)

if [[ -d /home/*/.flood ]]; then
    echo_error "Your flood installation is outdated/unsupported. Please reinstall flood"
    exit 1
fi

echo_progress_start "Upgrading flood"
npm install -g flood >> ${log} 2>&1
echo_progress_done

for user in "${users[@]}"; do
    systemctl try-restart flood${user}
done
