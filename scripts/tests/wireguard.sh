#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "wg-quick@wg$(id -u "$user")" || {
        echo_warn "wg-quick@wg$(id -u "$user") is not enabled, skipping"
        continue
    }
    check_service "wg-quick@wg$(id -u "$user")" || BAD=true

    echo_progress_start "Checking if interface is up for wg$(id -u "$user")"
    wg show wg"$(id -u "$user")" >> $log 2>&1 || {
        BAD=true
        echo_warn "Interface is down"
    }
    echo_progress_done

done

evaluate_bad "wireguard"
