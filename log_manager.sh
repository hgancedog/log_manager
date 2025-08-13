#!/bin/bash

# Enable strict mode and enhanced error handling
# set -eEuo pipefail

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
    sleep 2
    exit 0
}

function checkFile() {

    local file_path="$1"
    local regex='^[<][0-9]+>1[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+(-|[[^]]+])[[:space:]]+(.*)?'

    if [ ! -f "${file_path}" ]; then
        echo "❌ El archivo no existe o está vacío."
        return 1
    fi

    local line_number=0
    local valid=0
    local invalid=0

    while IFS= read -r line; do
        ((line_number++))
        if grep -Pq "${regex}" <<<"${line}"; then
            ((valid++))
        else
            ((invalid++))
            echo "log in line ${line_number} not known"
        fi
    done <"${file_path}"

    echo -e "----------------Report--------------"
    echo "${line_number} logs analized"
    echo "Valid: ${valid} logs"
    echo "Invalid: ${invalid}"

}

function main() {

    echo -e "[+][+][+] Starting program... [+][+][+]"
    sleep 5

    checkFile "$1"

    return 0
}

trap 'handleError "${LINENO}" "${BASH_COMMAND}"' ERR #if there are functions, to add stack trace!

trap ctrl_c INT

main "$@"
