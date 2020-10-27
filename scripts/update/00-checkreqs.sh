#!/bin/bash
# Checks if required functions are loaded before continuing with the update scripts.
# Function should be loaded on the next run (by `box`) without further need for interaction.

if ! command -v apt_install > /dev/null 2>&1 ; then
    echo
    echo "Due to internal restructuring please restart \`box update\`. You should only have to do this once."
    echo "Reason: Apt functions unavailable"
    kill -13 $(ps --pid $$ -oppid=)
    exit 1
fi

if ! command -v echo_error > /dev/null 2>&1 ; then
    echo
    echo "Due to internal restructuring please restart \`box update\`. You should only have to do this once."
    echo "Reason: Echo functions unavailable"
    kill -13 $(ps --pid $$ -oppid=)
    exit 1
fi

if [[ -z $log ]] ; then
    echo
    echo "Due to internal restructuring please restart \`box update\`. You should only have to do this once."
    echo "Reason: log not set"
    kill -13 $(ps --pid $$ -oppid=)
    exit 1
fi