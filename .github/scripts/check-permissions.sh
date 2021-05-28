#!/bin/bash
exit_code=0

# Check so that all shell scripts has 755
for file in ./scripts/**/*.sh; do
    permissions=$(stat -L -c "%a" $file)
    if [[ "$permissions" != "755" ]]; then
        exit_code=1
        echo "SH script '$file' has incorrect permissions '$permissions'"
    fi
done

exit "$exit_code"
