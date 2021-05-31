#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

#Check nginx only once beause if the config works for one, it will work for all
check_nginx "deluge" || BAD=true

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "deluged@$user" || {
        echo_warn "deluged@$user is not enabled, skipping"
        continue
    }

    check_service "deluged@$user" || {
        BAD=true
        continue
    }

    d_port=$(jq -r '.["daemon_port"]' < /home/"$user"/.config/deluge/core.conf | grep -e '^[0-9]*$')
    check_port "$d_port"
done

evaluate_bad
