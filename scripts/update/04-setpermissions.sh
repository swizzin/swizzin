#!/bin/bash

echo_progress_start "Setting correct permissions on swizzin files"

find /etc/swizzin/scripts -exec chmod 700 {} \;
find /etc/swizzin/sources -type f -exec chmod 600 {} \;
find /etc/swizzin/sources -type d -exec chmod 700 {} \;

echo_progress_done "Permissions set"
