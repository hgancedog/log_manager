#!/bin/bash

# Enable strict mode and enhanced error handling
set -eEuo pipefail

#Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
GRAY='\e[0;37m'
ENDCOLOR='\033[0m'

function handleError() {
    echo -e "Error in line: $1\tcommand: $2"   
}

function ctrl_c() {
    echo -e "\n${RED}[+][+][+] Exiting the program ... [+][+][+]${ENDCOLOR}"
    sleep 1
    exit 0
}

function checkFile () {

    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo -e "File is empty or doesn´t exists"
        return 1
    fi

    return 0
}

function main() {
    
    echo "Starting main function"

    checkFile "$1"
 
    return 0
}

trap 'handleError "${LINENO}" "${BASH_COMMAND}"' ERR #if there are functions, to add stack trace!

trap ctrl_c INT

echo -e "Imprimiendo prueba por pantalla"

main "$@"

