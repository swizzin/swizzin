#!/bin/bash
# Ensures all scrips has permissions so that they are executable

echo_progress_start "Checking permissions on swizzin files"

chmod -R 700 /etc/swizzin/scripts        # Set permissions of all scripts
chmod -R 600 /etc/swizzin/sources        # Sources are only `.` or `source`d and does not need to be executable
chmod 700 /etc/swizzin/sources/functions # Best to keep X permission on the folder inside sources

echo_progress_done "Permissions changed"
