#!/usr/bin/env bash

export SHELLCHECK_CODES="SC2086"
find scripts -type f -exec bash -c 'shellcheck "$1" -i $SHELLCHECK_CODES --format=diff | patch "$1"' none {} \;
