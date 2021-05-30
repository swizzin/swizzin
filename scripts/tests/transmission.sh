#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

#Check nginx only once beause if the config works for one, it will work for all
check_nginx "transmission" || bad=true

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "transmission@$user" || {
        echo_warn "transmission@$user is not enabled, skipping"
        continue
    }

    check_service "transmission@$user" || {
        bad=true
        continue
    }

    extra_params="--user $user:$(_get_user_password "$user")"
    port=$(jq -r ".[\"rpc-port\"]" < "/home/$user/.config/transmission-daemon/settings.json")
    check_port_curl "$port" "$extra_params" || bad=true
done

evaluate_bad
