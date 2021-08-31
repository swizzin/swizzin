#!/bin/bash
# LazyLibrarian remove script for swizzin
# Author: Aethaeran

##########################################################################
# Import Sources
##########################################################################

. /etc/swizzin/sources/functions/utils

##########################################################################
# Variables
##########################################################################

app_name="lazylibrarian"
pretty_name="LazyLibrarian"
app_dir="/opt/$app_name"
user="$(_get_app_owner "$app_name" "$LAZYLIB_OWNER")"
config_dir="/home/$user/.config/$app_name"
venv_dir="/opt/.venv/$app_name"

##########################################################################
# Main
##########################################################################

# TODO: Make sure these haven't changed since installation, as to avoid removing custom configs

if [[ -e "$venv_dir" ]]; then
    echo_progress_start "Removing $pretty_name venv..."
    # shellcheck disable=2154 # log variable is inherited from box itself.
    rm -rv "$venv_dir" >> "$log" 2>&1
    echo_progress_done
else
    echo_info "$pretty_name venv_dir didn't exist."
fi

if [[ -e "$app_dir" ]]; then
    echo_progress_start "Removing $pretty_name installation..."
    # shellcheck disable=2154 # log variable is inherited from box itself.
    rm -rv "$app_dir" >> "$log" 2>&1
    echo_progress_done
else
    echo_info "$pretty_name app_dir didn't exist."
fi

if [[ -e "$config_dir" ]]; then
    echo_progress_start "Removing $pretty_name configuration..."
    rm -rv "$config_dir" >> "$log" 2>&1
    echo_progress_done
else
    echo_info "$pretty_name config_dir didn't exist."
fi

if [[ -e "/etc/systemd/system/$app_name.service" ]]; then
    echo_progress_start "Removing $pretty_name systemd service..."
    if [[ $(systemctl is-active "$app_name") == "active" ]]; then
        systemctl stop "$app_name" --quiet
    fi
    if [[ $(systemctl is-enabled "$app_name") == "enabled" ]]; then
        systemctl disable "$app_name" --quiet
    fi
    rm -v "/etc/systemd/system/$app_name.service" >> "$log" 2>&1
    echo_progress_done
else
    echo_info "$pretty_name systemd service didn't exist."
fi

if [[ -e "/etc/nginx/apps/$app_name.conf" ]]; then
    echo_progress_start "Removing $pretty_name nginx configuration..."
    rm -v "/etc/nginx/apps/$app_name.conf" >> "$log" 2>&1
    echo_progress_done
else
    echo_info "$pretty_name nginx configuration didn't exist."
fi

if [[ -e "/install/.$app_name.lock" ]]; then
    echo_progress_start "Removing $pretty_name lock..."
    rm -v "/install/.$app_name.lock" >> "$log" 2>&1
    echo_progress_done
else
    echo_info "$pretty_name lock didn't exist."
fi
