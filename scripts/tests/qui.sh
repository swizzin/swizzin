#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "qui@$user" || {
        echo_log_only "qui@$user is not enabled, skipping"
        continue
    }

    atleastonerunning=true

    check_service "qui@$user" || {
        BAD=true
        continue
    }

    extra_params="--user $user:$(_get_user_password "$user")"
    confpath="/home/${user}/.config/qui/config.toml"
    port=$(grep -e '^port' "$confpath" | cut -d' ' -f3)
    check_port_curl "$port" "$extra_params" || BAD=true
done

if [[ "$atleastonerunning" = "true" ]]; then
    #Check nginx only once beause if the config works for one, it will work for all
    check_nginx "qui" || BAD=true
    evaluate_bad "qui"
else
    echo_warn "No qui instance was running"
fi