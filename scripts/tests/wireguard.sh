#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "wg-quick@wg$(id -u "$user")" || {
        echo_log_only "wg-quick@wg$(id -u "$user") is not enabled, skipping"
        continue
    }
    atleastonerunning=true

    check_service "wg-quick@wg$(id -u "$user")" || BAD=true

    wg show wg"$(id -u "$user")" >> $log 2>&1 || {
        BAD=true
        echo_warn "wg Interface for $user is down"
    }

done

if [[ "$atleastonerunning" = "true" ]]; then
    #Check nginx only once beause if the config works for one, it will work for all
    evaluate_bad "wireguard"
else
    echo_warn "No wireguard instance was running"
fi
