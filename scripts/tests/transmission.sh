#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    check_service "transmission@$user" || bad=true

    extra_params="--user $user:$(_get_user_password "$user")"
    check_nginx "transmission" "$extra_params" || bad=true

    port=$(jq -r ".[\"rpc-port\"]" < "/home/$user/.config/transmission-daemon/settings.json")
    check_port "$port" "$extra_params" || bad=true
done

evaluate_bad
