#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "transmission@$user" || {
        echo_log_only "transmission@$user is not enabled, skipping"
        continue
    }

    atleastonerunning=true

    check_service "transmission@$user" || {
        BAD=true
        continue
    }

    extra_params="--user $user:$(_get_user_password "$user")"
    port=$(jq -r ".[\"rpc-port\"]" < "/home/$user/.config/transmission-daemon/settings.json")
    check_port_curl "$port" "$extra_params" || BAD=true
done

if [[ "$atleastonerunning" = "true" ]]; then
    #Check nginx only once beause if the config works for one, it will work for all
    check_nginx "transmission" || BAD=true
else
    echo_log_only "No transmission instance was running, skipping nginx check"
fi

evaluate_bad "transmission"
