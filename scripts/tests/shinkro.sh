#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "shinkro@$user" || {
        echo_log_only "shinkro@$user is not enabled, skipping"
        continue
    }

    atleastonerunning=true

    check_service "shinkro@$user" || {
        BAD=true
        continue
    }

    extra_params="--user $user:$(_get_user_password "$user")"
    confpath="/home/${user}/.config/shinkro/config.toml"
    port=$(grep -e '^Port' "$confpath" | cut -d' ' -f3)
    check_port_curl "$port" "$extra_params" || BAD=true
done

if [[ "$atleastonerunning" = "true" ]]; then
    #Check nginx only once because if the config works for one, it will work for all
    check_nginx "shinkro" || BAD=true
    evaluate_bad "shinkro"
else
    echo_warn "No shinkro instance was running"
fi
