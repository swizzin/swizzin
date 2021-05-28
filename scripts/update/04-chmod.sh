#!/bin/bash
# Ensures all scrips has permissions so that they are executable

# Set permissions of all scripts
chmod -R 700 /etc/swizzin/scripts

# Sources are only `.` or `source`d and does not need to be executable
chmod -R 600 /etc/swizzin/sources
