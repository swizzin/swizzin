#!/bin/bash
# JDownloader Installer for swizzin
# Author: Aethaeran

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

app_name="jdownloader"
pretty_name="JDownloader"

# TODO: Check if services are running. on each instance

readarray -t users < <(_get_user_list)  # Install a separate JDownloader instance for each user, as it cannot be multi-seated.
for user in "${users[@]}"; do
    check_service "$app_name@$user"
done

# TODO: Check if http server is up
# TODO: Check if myjdownloader.org is up
# TODO: Check if MyJDownloader details are verified on each instance
