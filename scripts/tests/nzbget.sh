#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

readarray -t users < <(_get_user_list)
for user in "${users[@]}"; do
    systemctl -q is-enabled "nzbget@$user" || {
        echo_log_only "nzbget@$user is not enabled, skipping"
        continue
    }

    atleastonerunning=true

    check_service "nzbget@$user" || {
        BAD=true
        continue
    }
    confpath="/home/${user}/nzbget/nzbget.conf"
    port=$(grep 'ControlPort' "$confpath" | cut -d= -f2)
    check_port_curl "$port" "$extra_params" || BAD=true
done

if [[ "$atleastonerunning" = "true" ]]; then
    #Check nginx only once beause if the config works for one, it will work for all
    check_nginx "nzbget" || BAD=true
    evaluate_bad "nzbget"
else
    echo_warn "No nzbget instance was running"
fi
