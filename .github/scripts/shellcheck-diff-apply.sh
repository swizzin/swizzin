#!/usr/bin/env bash

export SHELLCHECK_CODES="SC2086"
echo -e "---\tChecking all .sh files"
find . -type f -name \*.sh -exec bash -c 'shellcheck "$1" -i $SHELLCHECK_CODES --format=diff | patch "$1"' none {} \;

echo -e "---\tChecking all sources/functions files"
find sources/functions -type f -exec bash -c 'shellcheck "$1" -i $SHELLCHECK_CODES --format=diff | patch "$1"' none {} \;
