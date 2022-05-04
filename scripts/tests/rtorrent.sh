#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "rtorrent@$user" || {
        echo_log_only "rtorrent@$user is not enabled, skipping"
        continue
    }
    check_service "rtorrent@$user" || BAD=true
done

evaluate_bad "rtorrent"
