#!/bin/bash
# Ensures all scrips has permissions so that they are executable

echo_info "Setting permissions of scripts"
# Set permissions of all scripts
chmod -R 700 /etc/swizzin/scripts

echo_info "Setting permissions of sources"
# Sources are only `.` or `source`d and does not need to be executable
chmod -R 600 /etc/swizzin/sources
