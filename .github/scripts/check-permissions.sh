#!/bin/bash
exit_code=0

check_permission() {
    expected=$1
    file=$2

    permissions=$(stat -L -c "%a" "$file")
    if [ "$permissions" != "$expected" ]; then
        echo "'$file' has incorrect permissions '$permissions', should be '$expected'"
        return 1
    fi
}

# Check so that all scripts has --rwxr-xr-x = 755
for file in $(find scripts); do
    check_permission 755 "$file" || exit_code=1
done

# Check so that all sources has --rw-r--r-- = 644
for file in $(find sources -type f); do
    check_permission 644 "$file" || exit_code=1
done

# Check so that all directories in sources has --rwxr-xr-x = 755
for folder in $(find sources -type d); do
    check_permission 755 "$folder" || exit_code=1
done

exit "$exit_code"
