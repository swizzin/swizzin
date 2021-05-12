#!/bin/bash
# Checks if required functions are loaded before continuing with the update scripts.
# Function should be loaded on the next run (by `box`) without further need for interaction.

# DO NOT SOURCE GLOBALS HERE, THAT DEFEATS THE WHOLE PURPOSE OF THIS CHECK
# SOURCING GLOBALS HERE WILL MAKE THESE TESTS PASS BUT THE FUNCTIONS WON'T BE AVAILABLE IN THE SHELL ABOVE

killage() {
    echo
    echo "Due to internal restructuring please run \`box update\` again. You should only have to do this once."
    echo "Reason: $1"
    kill -13 $(ps --pid $$ -oppid=)
    exit 1
}
if ! command -v apt_install > /dev/null 2>&1; then
    killage "Apt functions unavailable"
fi

if ! command -v echo_error > /dev/null 2>&1; then
    killage "Echo functions unavailable"
fi

if [[ -z $log ]]; then
    killage "Log variable not set"
fi

if ! swizdb list > /dev/null 2>&1; then
    killage "SwizDB list command unavailable"
fi

if [[ -z $SWIZ_REPO_SCRIPT_RAN ]]; then
    killage "Updating procedure restructured"
fi
