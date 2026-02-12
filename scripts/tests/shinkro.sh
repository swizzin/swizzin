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

    confpath="/home/${user}/.config/shinkro/config.toml"
    port=$(grep -e '^Port' "$confpath" | cut -d' ' -f3)
    echo_log_only "Checking if port $port/shinkro is reachable via curl"
    #shinkro run on port/BaseUrl and needs to query it instead of just port for this test
    curl -sSfLk http://127.0.0.1:"$port"/shinkro/ -o /dev/null >> "$log" 2>&1 || {
        echo_warn "Querying http://127.0.0.1:$port/shinkro/ failed"
        BAD=true
    }
done

if [[ "$atleastonerunning" = "true" ]]; then
    #Check nginx only once because if the config works for one, it will work for all
    check_nginx "shinkro" || BAD=true
    evaluate_bad "shinkro"
else
    echo_warn "No shinkro instance was running"
fi
