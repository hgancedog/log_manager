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
BOLD='\033[1m'
UNDERLINE='\033[4m'
HIGHLIGHT='\033[30;43m'
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
    echo
    echo
    echo -e " ${BLUE}---------------   LOG MESSAGES (PRI DECODED)   ---------------${ENDCOLOR}"
    echo

    printf " ${MAGENTA}%-8s${ENDCOLOR} ${WHITE}%-10s${ENDCOLOR} ${YELLOW}%-23s${ENDCOLOR} %s${ENDCOLOR}\n" "SEVERITY" "FACILITY" "DATE" "MESSAGE"
    echo

    # This ensures a clean file for each run.
    : >"log_parsed.txt"
    for ((i = 0; i < global_valid_logs; i++)); do
        printf " ${MAGENTA}%-8s${ENDCOLOR} ${WHITE}%-10s${ENDCOLOR} ${YELLOW}%s${ENDCOLOR} %s\n" "${sevKeyMsg[$i]}" "${facKeyMsg[$i]}" "${dateMsg[$i]}" "${log_msgMsg[$i]}"
        printf " %-8s %-10s %s %s\n" "${sevKeyMsg[$i]}" "${facKeyMsg[$i]}" "${dateMsg[$i]}" "${log_msgMsg[$i]}" >>"log_parsed.txt"
    done

    echo
    echo
    echo
    echo -e " ${MAGENTA}---------------  COUNTS BY SEVERITY  ---------------${ENDCOLOR}"
    echo

    for ((i = 0; i < ${#sevArr[@]}; i++)); do
        sevKey="${sevArr[$i]}"
        sevCount="${sevCountArr[$sevKey]:-0}"
        printf " ${MAGENTA}%-8s${ENDCOLOR}%-5s" "${sevKey}:" "${sevCount}"
    done

    echo
    echo
    echo
    echo -e " ${WHITE}---------------  COUNTS BY FACILITY  ---------------${ENDCOLOR}"
    echo

    for facKey in "${facArr[@]}"; do
        facCount="${facCountArr[$facKey]:-0}"
        echo " ${facKey}: ${facCount}"
    done | column -x

    echo
    echo
    echo

    echo -e " ${YELLOW}---------------  TABLE FACILITY/SEVERITY BREAKDOWN  ---------------${ENDCOLOR}"
    echo

    local term_width
    term_width=$(tput cols)

    local n_fac=${#facArr[@]}

    local col_width
    col_width=$((term_width / (n_fac + 3)))

    echo -e "  ${BLUE}Facility →${ENDCOLOR}"

    # Cabecera de facilities
    printf "${RED}%-${col_width}s${ENDCOLOR}|" "Severity↓"
    for ((i = 0; i < n_fac; i++)); do
        fac="${facArr[$i]}"
        printf "${BLUE}%-${col_width}s${ENDCOLOR}" "  $fac"
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
        printf "${RED}%-${col_width}s${ENDCOLOR}|" " $sev"
        for ((i = 0; i < n_fac; i++)); do
            fac="${facArr[$i]}"
            val="${sevFacCountArr["$sev:$fac"]:-0}"
            printf "${GRAY}%-${col_width}s${ENDCOLOR}" "     $val"
        done
        echo
    done

    echo
    echo -e " ---------------  ${RED}REPORT FINISHED${ENDCOLOR}  ---------------"
    echo
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
    local file_name
    file_name="$(basename "${file_path}")"
    local regex='^[<][0-9]+>1[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+(-|[[^]]+])[[:space:]]+(.*)?'

    if [ ! -f "${file_path}" ]; then
        echo -e "❌ El archivo no existe o está vacío."
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
            ((invalid_logs++))
            unknownLogs+=("$line_number")
        fi
    done <"${file_path}"

    echo
    echo
    echo -e " ${RED}---------------  LOG MANAGER REPORT   ---------------${ENDCOLOR}"
    echo
    echo -e " ${YELLOW}Analyzed file name:${ENDCOLOR} ${WHITE}${file_name}${ENDCOLOR}"
    echo " ${line_number} logs analized"
    echo " Valid: ${global_valid_logs} logs"

    oldIFS=$IFS

    if [ ${#unknownLogs[@]} -eq 0 ]; then
        joinedUnknown="---"
    else
        IFS=',' joinedUnknown="${unknownLogs[*]}"
        IFS="$oldIFS"
    fi

    echo -e " ${RED}Invalid: ${invalid_logs} logs${ENDCOLOR}"
    echo -e " ${RED}Invalid format log entries found in input file at line number(s): ${joinedUnknown}${ENDCOLOR}"
    echo -e " Output file ${WHITE}'log_parsed.txt'${ENDCOLOR} created"
    echo
    echo -e " ${WHITE}Log messages have been parsed: the PRI value has been replaced with its corresponding Severity and Facility fields. The log messages are displayed below, and a copy has also been written to the output file to facilitate filtering with tools like grep (e.g., grep 'crit', grep 'err', etc.).${ENDCOLOR}"
    echo
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

# Unknown logs array
declare -a unknownLogs sevKeyMsg facKeyMsg dateMsg log_msgMsg

# Counting arrays
declare -A sevCountArr facCountArr sevFacCountArr

main "$@"
