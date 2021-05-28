#!/bin/bash
exit_code=0

# Check so that all scripts has --rwxr-xr-x = 755
for file in ./scripts/**/*; do
    permissions=$(stat -L -c "%a" "$file")
    if [[ "$permissions" != "755" ]]; then
        exit_code=1
        echo "'$file' has incorrect permissions '$permissions', should be '755'"
    fi
done

exit "$exit_code"
