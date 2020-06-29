#! /bin/bash
# Ensures that dependencies are installed and corrects them if that is not the case.

#space-separate required dependencies
dependencied="jq sl"

_check_installed (){
    if dpkg -s "$1" > /dev/null 2>&1; then
        return 0
    else 
        return 1
    fi
}

missing=""
for dep in $dependencied; do
    if ! _check_installed "$dep"; then 
        missing+="$dep "
    fi
done

if [[ $missing != "" ]]; then 
    echo "Missing the following dependencies: $missing"
    apt-get install -yq "$missing"
fi