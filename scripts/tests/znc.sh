#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "znc" || BAD=true

port=$(cat /home/znc/.znc/configs/znc.conf | grep -i "Port =" | awk '{print $3}')
check_port "$port" || BAD=true

evaluate_bad "znc"
