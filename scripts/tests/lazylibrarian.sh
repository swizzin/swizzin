#!/usr/bin/env bash
# LazyLibrarian test script for swizzin
# Author: Aethaeran

##########################################################################
# References
##########################################################################

# https://github.com/swizzin/swizzin/blob/master/scripts/tests/_basetest.sh

##########################################################################
# Import Sources
##########################################################################

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

##########################################################################
# Variables
##########################################################################

app_name="lazylibrarian"

##########################################################################
# Functions
##########################################################################

check_port_curl() {
    echo_progress_start "Checking if port $1 is reachable via curl"
    if [ "$1" -eq "$1" ] 2> /dev/null; then
        port=$1
    else
        port=$(get_port "$1") || {
            echo_warn "Couldn't guess port"
            return 1
        }
    fi
    extra_params="$2"
    # shellcheck disable=SC2086 # We want splitting on the extra params variable. So the warning is void here.
    curl -sSfLk $extra_params http://127.0.0.1:"$port/$app_name" -o /dev/null || {
        echo_warn "Querying http://127.0.0.1:$port/$app_name failed"
        echo
        return 1
    }
    echo_progress_done
}

##########################################################################
# Main
##########################################################################

# run all functions, if one fails, mark as bad
check_service "$app_name" || BAD="true"
check_port "$app_name" || BAD="true"
check_port_curl "$app_name" || BAD="true"
# shellcheck disable=SC2034 # $BAD is used in evaluate_bad. So the warning is void here.
check_nginx "$app_name" || BAD="true"

evaluate_bad
