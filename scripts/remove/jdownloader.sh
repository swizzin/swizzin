#!/bin/bash
# JDownloader remover for swizzin
# Author: Aethaeran

# Import functions
. /etc/swizzin/sources/functions/utils

# this will check for all swizzin users, and iterate and remove all JDownloader installations.
users=("$(_get_user_list)")

# TODO: Add bypass purging altogether with variable
# TODO: Move purging functionality to a function outside this script

# Do a check to see if they want to purge JDownloader configurations.
if ask "Do you want to purge ANY JDownloader configurations?" N; then
    purge_some="false" # If no
    echo_info "Each user's JDownloader configuration can be found in their home folder under the sub-directory 'jd2'"
else
    purge_some="true" # If yes
    if ask "Do you want to purge ALL JDownloader configurations?" N; then
        purge_all="true" # If yes
    else
        purge_all="false" # If no
    fi
fi

# The following line cannot follow SC2068 because it will cause the list to become a string.
# shellcheck disable=SC2068
for user in ${users[@]}; do
    echo_progress_start "Removing JDownloader for $user..."
    systemctl disable -q --now jdownloader@"$user"
    JD_HOME="/home/$user/jd2"
    if [[ $purge_all == "true" ]]; then
        rm_if_exists $JD_HOME
    else
        if [[ $purge_some == "true" ]]; then
            if ask "Do you want to purge $user's JDownloader configuration?" N; then
                rm_if_exists $JD_HOME # If yes
            else
                echo_info "Not purging JDownloader configuration for $user\n their JDownloader configuration can be found at $JD_HOME"
            fi
        fi
    fi
    echo_progress_done
done
echo_progress_start "Removing shared JDownloader files..."
rm_if_exists -r /etc/systemd/system/jdownloader@.service
rm_if_exists /install/.jdownloader.lock
echo_progress_done
echo_success "JDownloader removed"
echo_info "If JDownloader was the only thing using Java, and Java was installed with JDownloader. Then you can uninstall default-jre with 'apt remove default-jre -y'. It's not done by default because you may have other services using it."
