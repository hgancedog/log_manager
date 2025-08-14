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

function analyzeLog {
    local log=$1
    local pri
    local date
    local sev
    local fac
    local log_msg

    # Counting arrays
    sevArr=("emerg" "alert" "crit" "err" "warn" "notice" "info" "debug")
    facArr=("kern" "user" "mail" "daemon" "auth" "syslog" "lpr" "news" "uucp" "cron" "authpriv" "ftp" "ntp" "audit" "alert")

    pri="$(echo "${log}" | awk '{match($1, /<([0-9]+)>/, m); print m[1]}')"
    date="$(echo "$log" | awk '{print $2}')"
    sev=$((pri % 8))
    fac=$((pri / 8))

    log_msg=$(echo "${log}" | awk '{print substr($0, index($0, "- -") + length("- -"))}')

    # Building final log
    while read -r sev fac date rest; do

        sevStr="${sevArr[$sev]}"
        length_facArr="${#facArr[@]}"

        if [ "${fac}" -lt "${length_facArr}" ]; then
            facStr="${facArr[$fac]}"
        else
            facStr="[unknown]"
        fi

        printf "%-8s %-10s %s %s\n" "${sevStr}" "${facStr}" "${date}" "${rest}"
    done < <(
        printf "%d %d %s %s\n" "${sev}" "${fac}" "${date}" "${log_msg}" |
            sort -k1,1n -k3,3
    )

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
            analyzeLog "${line}"
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

    checkFile "$1"

    return 0
}

trap 'handleError "${LINENO}" "${BASH_COMMAND}"' ERR

trap ctrl_c INT

main "$@"
