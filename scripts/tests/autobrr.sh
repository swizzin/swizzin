#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "autobrr@$user" || {
        echo_log_only "autobrr@$user is not enabled, skipping"
        continue
    }

    atleastonerunning=true

    check_service "autobrr@$user" || {
        BAD=true
        continue
    }

    extra_params="--user $user:$(_get_user_password "$user")"
    confpath="/home/${user}/.config/autobrr/config.toml"
    port=$(grep -e '^port' "$confpath" | cut -d' ' -f3)
    check_port_curl "$port" "$extra_params" || BAD=true
done

if [[ "$atleastonerunning" = "true" ]]; then
    #Check nginx only once beause if the config works for one, it will work for all
    check_nginx "autobrr" || BAD=true
    evaluate_bad "autobrr"
else
    echo_warn "No autobrr instance was running"
fi
