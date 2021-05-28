#!/bin/bash

echo_progress_start "Setting correct permissions on swizzin files"

find /etc/swizzin/scripts -exec chmod 700 {} \; # Set X on all subfolders of `sources`
find /etc/swizzin/sources -exec chmod 700 {} \; # Set X on all subfolders of `sources`

echo_progress_done "Permissions set"
