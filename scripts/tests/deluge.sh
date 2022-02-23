#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "deluged@$user" || {
        echo_log_only "deluged@$user is not enabled, skipping"
        continue
    }

    check_service "deluged@$user" || {
        BAD=true
        continue
    }

    d_port=$(jq -r '.["daemon_port"]' < /home/"$user"/.config/deluge/core.conf | grep -e '^[0-9]*$')
    check_port "$d_port"
done

evaluate_bad "deluge"
