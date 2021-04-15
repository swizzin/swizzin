#!/bin/bash
#
# Create the symlink /etc/bash_completion.d/box if it does not exist and output a helpful echo
if [[ ! -e /etc/bash_completion.d/box ]]; then
    ln -s '/etc/swizzin/sources/bash_completion' '/etc/bash_completion.d/box'
    echo_info "Shell completions for the box command have been installed. They will be applied the next time you log into a bash shell"
fi

# Create our apps and upgrade lists for the completion arrays. This is fired everytime this script is run to make sure the lists are current.
swizdb set bash_completion/apps.list "$(find "/etc/swizzin/scripts/install/" -type f -exec basename {} \; | sort)"
swizdb set bash_completion/upgrade.list "$(find "/etc/swizzin/scripts/upgrade/" -type f -exec basename {} \; | sort)"

# Check to make sure the completion file /etc/swizzin/sources/bash_completion is set to 644
if [[ $(stat -c '%A' /etc/swizzin/sources/bash_completion) != '-rw-r--r--' ]]; then
    chmod 644 '/etc/swizzin/sources/bash_completion'
fi

# Check to make sure the directory /var/lib/swizzin/db/bash_completion is set to 755
if [[ $(stat -c '%A' /var/lib/swizzin/db/bash_completion) != 'drwxr-xr-x' ]]; then
    chmod 755 '/var/lib/swizzin/db/bash_completion'
fi

# Add all files in /var/lib/swizzin/db/bash_completion to the bash_completion_perms array to process in our for below
readarray -t bash_completion_perms < <(find "/var/lib/swizzin/db/bash_completion" -type f -exec basename {} \;)
# Using a for and the bash_completion_perms array check through all files in the /var/lib/swizzin/db/bash_completion have 644 perms set otherwise do nothing
for file_names in "${bash_completion_perms[@]}"; do
    if [[ "$(stat -c '%A' "/var/lib/swizzin/db/bash_completion/${file_names}")" != '-rw-r--r--' ]]; then
        chmod 644 "/var/lib/swizzin/db/bash_completion/${file_names}"
    fi
done
