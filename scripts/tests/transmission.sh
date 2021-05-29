#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    check_service "transmission@$user" || bad=true

    confpath="/home/$user/.config/transmission-daemon/settings.json"
    key="rpc-port"
    paramrr=".[\"$key\"]"
    port=$(jq -r "$paramrr" < "$confpath")
    extra_params="--user $user:$(_get_user_password "$user")"

    check_port "$port" "$extra_params" || bad=true
    check_nginx "transmission" "$extra_params" || bad=true
done

evaluate_bad
