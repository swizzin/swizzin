#!/bin/bash
# One place to keep track of the functions that are being sourced in at the beginning of the `box` and `setup.sh` scripts.
# Please ensure that any functions or variables you'd like to have available through sourcing in this file need to be exported.
# This means `export $variable` or `export -f function_name `.
# If you're planning to test single scripts outside of either `box` or `setup.sh` context, source this very file in your
# shell, and the functions and variables will be available until it is terminated.

export log="/var/log/swizzin/box.log"

############################################
# FUNCTIONS
############################################

# Provides the functions like `echo_info` and others. All of these will automatically log to $log
# shellcheck source=sources/functions/color_echo
. /etc/swizzin/sources/functions/color_echo

# Parsing things like OS names and version, architecture, etc
#shellcheck source=sources/functions/os
. /etc/swizzin/sources/functions/os

# Managing calls to `apt-get` in a streamlined and preventative manner
#shellcheck source=sources/functions/apt
. /etc/swizzin/sources/functions/apt

# A script to standardise yes/no dialogues
#shellcheck source=sources/functions/ask
. /etc/swizzin/sources/functions/ask

# A script to offer user and password management functions
#shellcheck source=sources/functions/users
. /etc/swizzin/sources/functions/users

# Tool to manage key-value pairs on filesystem in persistent storage
#shellcheck source=sources/functions/swizdb
. /etc/swizzin/sources/functions/swizdb
