#!/bin/bash
#
# Create the symlink /etc/bash_completion.d/swizzin if it does not exist and output a helpful echo
if [[ ! -e /etc/bash_completion.d/swizzin ]]; then
    ln -s '/etc/swizzin/sources/bash_completion/swizzin' '/etc/bash_completion.d/swizzin'
    echo_info "Shell completions for the box command have been installed. They will be applied the next time you log into a bash shell"
fi
# Create our apps and upgrade lists for the completion arrays. This is fired everytime this script is run to make sure the lists are current.
find "/etc/swizzin/scripts/install/" -type f -exec basename {} \; | sort > /etc/swizzin/sources/bash_completion/completion.apps
find "/etc/swizzin/scripts/upgrade/" -type f -exec basename {} \; | sort > /etc/swizzin/sources/bash_completion/completion.upgrade
# Add all files in /etc/swizzin/sources/bash_completion to the bash_completion_perms array to process in our for below
readarray -t bash_completion_perms < <(find "/etc/swizzin/sources/bash_completion" -type f -exec basename {} \;)
# Check to make sure the directory /etc/swizzin/sources/bash_completion is set to 755 otherwise chmod it to 755
if [[ $(stat -c '%A' /etc/swizzin/sources/bash_completion) != 'drwxr-xr-x' ]]; then
    chmod 755 '/etc/swizzin/sources/bash_completion'
fi
# Using a for and the bash_completion_perms array check through all files in the /etc/swizzin/sources/bash_completion have 644 perms set otherwise do nothing
for file_names in "${bash_completion_perms[@]}"; do
    if [[ "$(stat -c '%A' "/etc/swizzin/sources/bash_completion/${file_names}")" != '-rw-r--r--' ]]; then
        chmod 644 "/etc/swizzin/sources/bash_completion/${file_names}"
    fi
done
