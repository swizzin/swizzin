#!/bin/bash
# JDownloader remover for swizzin
# Author: Aethaeran

# Import swizzin utils
. /etc/swizzin/sources/functions/utils

# this will check for all swizzin users, and iterate and remove all JDownloader installations.
users=("$(_get_user_list)")
# The following line cannot follow SC2068 because it will cause the list to become a string.
# shellcheck disable=SC2068
for user in ${users[@]}; do
    echo_progress_start "Removing JDownloader for $user..."
    systemctl disable -q --now jdownloader@"$user"
    # TODO: Do a check to see if they want to purge their JDownloader configurations.
    rm_if_exists -r /home/"$user"/jd2
    echo_progress_done
done
echo_progress_start "Removing shared JDownloader files..."
rm_if_exists -r /etc/systemd/system/jdownloader@.service
rm_if_exists /install/.jdownloader.lock
echo_progress_done
echo_success "JDownloader removed"
echo_info "If JDownloader was the only thing using Java, and Java was installed with JDownloader. Then you can uninstall default-jre with 'apt remove default-jre -y'. It's not done by default because you may have other services using it."
