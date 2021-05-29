#!/usr/bin/env bash

echo -e "---\tListing all shellcheck warning"
find . -type f -name \*.sh -exec bash -c 'shellcheck "$1" -S warning' none {} \;
find sources/functions -type f -exec bash -c 'shellcheck "$1" -S warning' none {} \;

export EXPLICIT_SHCK_CODES="SC2086,SC2164"
echo -e "---\tAutofixing all .sh files"
find . -type f -name \*.sh -exec bash -c 'shellcheck "$1" -i $EXPLICIT_SHCK_CODES --format=diff | patch "$1"' none {} \;

echo -e "---\tAutofixing all sources/functions files"
find sources/functions -type f -exec bash -c 'shellcheck "$1" -i $EXPLICIT_SHCK_CODES --format=diff | patch "$1"' none {} \;
