#!/bin/bash

echo_progress_start "Setting correct permissions on swizzin files"

chmod -R 700 /etc/swizzin/scripts                       # Set permissions of all scripts
chmod -R 600 /etc/swizzin/sources                       # Sources are only `source`d and does not need to be executable
find /etc/swizzin/sources -type d -exec chmod 700 {} \; # Set X on all subfolders of `sources`

echo_progress_done "Permissions set"
