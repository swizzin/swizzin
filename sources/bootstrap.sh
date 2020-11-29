#!/bin/bash
# One place to keep track of the functions that are being pulled in by default

#Exporting environment values
export log="/root/logs/swizzin.log"

# Sourcing functions
# shellcheck source=sources/functions/color_echo
. /etc/swizzin/sources/functions/color_echo
#shellcheck source=sources/functions/os
. /etc/swizzin/sources/functions/os
#shellcheck source=sources/functions/apt
. /etc/swizzin/sources/functions/apt
#shellcheck source=sources/functions/ask
. /etc/swizzin/sources/functions/ask