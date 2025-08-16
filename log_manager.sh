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

function updateCounts {
    local sevKey="$1"
    local facKey="$2"

    ((sevCountArr["$sevKey"]++))
    ((facCountArr["$facKey"]++))
    ((sevFacCountArr["$sevKey:$facKey"]++))
}

function printFinalReport {

    # Final log parsed
    echo -e "--------- Log Messages Parsed  ---------------------------"

    for ((i = 0; i < global_valid_logs; i++)); do
        printf "%-8s %-10s %s %s\n" "${sevKeyMsg[$i]}" "${facKeyMsg[$i]}" "${dateMsg[$i]}" "${log_msgMsg[$i]}"
    done

    echo -e "--------- Severity Counts ---------------------------"

    # Necesitamos recorrer el array de nombres para poner los severity por orden (0,1, etc) y ya despues convertir el valor al nombre del severity
    # e imprimir el resultado de sevCount
    for ((i = 0; i < ${#sevArr[@]}; i++)); do
        key="${sevArr[$i]}"
        count="${sevCountArr[$key]:-0}"
        echo "${key}: ${count}"
    done

    echo -e "--------- Facility Counts ---------------------------"

    # Necesitamos recorrer el array de nombres para poner los severity por orden (0,1, etc) y ya despues convertir el valor al nombre del severity
    # e imprimir el resultado de sevCount
    for ((i = 0; i < ${#facArr[@]}; i++)); do
        key="${facArr[$i]}"
        count="${facCountArr[$key]:-0}"
        echo "${key}: ${count}"
    done

    echo -e "------------- Severity:Facility -------------------------------"

    for key in "${!sevFacCountArr[@]}"; do
        echo "$key: ${sevFacCountArr[$key]}"
    done

    echo -e "------------------2d Table -------------------------------------"

    local term_width
    term_width=$(tput cols)

    local n_fac=${#facArr[@]}

    local col_width
    col_width=$((term_width / (n_fac + 3)))

    echo -e "  Facility →"

    # Cabecera de facilities
    printf "%-${col_width}s|" "Severity↓"
    for ((i = 0; i < n_fac; i++)); do
        fac="${facArr[$i]}"
        printf "%-${col_width}s" " $fac"
    done
    echo

    # Línea de separación cabecera
    printf '%*s' $((col_width)) '' | tr ' ' '-'
    printf "+"
    for ((i = 0; i < n_fac; i++)); do
        printf '%*s' $((col_width)) '' | tr ' ' '-'
    done
    echo

    # Filas de resultados
    for sev in "${sevArr[@]}"; do
        printf "%-${col_width}s|" " $sev"
        for ((i = 0; i < n_fac; i++)); do
            fac="${facArr[$i]}"
            val="${sevFacCountArr["$sev:$fac"]:-0}"
            printf "%-${col_width}s" "   $val"
        done
        echo
    done

}

function parseLog {
    local log=$1
    local pri
    local date
    local sev
    local fac
    local log_msg
    local sevKey
    local facKey

    pri="$(echo "${log}" | awk '{match($1, /<([0-9]+)>/, m); print m[1]}')"
    date="$(echo "$log" | awk '{print $2}')"
    log_msg=$(echo "${log}" | awk '{print substr($0, index($0, "- -") + length("- -"))}')

    sev=$((pri % 8))
    fac=$((pri / 8))

    sevKey="${sevArr["$sev"]}"

    # Get the last valid index of the array
    last_fac_index=$((${#facArr[@]} - 1))

    # Check if the calculated 'fac' value is a valid index for our array
    if [ "$fac" -ge 0 ] && [ "$fac" -le "$last_fac_index" ]; then
        # If it's valid, assign the correct facility name
        facKey="${facArr[$fac]}"
    else
        # If it's out of range, assign the "[Unknown]" value directly
        facKey="${facArr[$last_fac_index]}"
    fi

    echo -e "${sevKey}|${facKey}|${date}|${log_msg}"
}

function checkFile() {

    local file_path="$1"
    local regex='^[<][0-9]+>1[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+(-|[[^]]+])[[:space:]]+(.*)?'

    if [ ! -f "${file_path}" ]; then
        echo "❌ El archivo no existe o está vacío."
        return 1
    fi

    local line_number=0
    local invalid_logs=0

    while IFS= read -r line; do
        ((line_number++))
        if grep -Pq "${regex}" <<<"${line}"; then

            ((global_valid_logs++))

            local parsed
            parsed="$(parseLog "${line}")"

            IFS="|" read -r sevKey facKey date log_msg <<<"$parsed"

            # Creating arrays with parsed elements for printing final log
            sevKeyMsg+=("$sevKey")
            facKeyMsg+=("$facKey")
            dateMsg+=("$date")
            log_msgMsg+=("$log_msg")

            updateCounts "$sevKey" "$facKey"

        else
            ((invalid++))
            echo "log in line ${line_number} not known"
        fi
    done <"${file_path}"

    echo -e "----------------Report--------------"
    echo "${line_number} logs analized"
    echo "Valid: ${global_valid_logs} logs"
    echo "Invalid: ${invalid_logs}"

}

function main() {

    global_valid_logs=0

    checkFile "$1"

    printFinalReport

    return 0
}

trap 'handleError "${LINENO}" "${BASH_COMMAND}"' ERR

trap ctrl_c INT

# Severity and Facility arrays
sevArr=("emerg" "alert" "crit" "err" "warn" "notice" "info" "debug")
facArr=("kern" "user" "mail" "daemon" "auth" "syslog" "lpr" "news" "uucp" "cron" "authpriv" "ftp" "ntp" "audit" "alert" "reserved" "[Unknown]")

# Counting arrays
declare -A sevCountArr facCountArr sevFacCountArr

main "$@"
