#!/usr/bin/env bash

# Enable strict mode and enhanced error handling.
# set -eEuo pipefail

# --- Color variables for console output ---
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

# --- Function Definitions ---

# handleError: Prints an error message with line number and command.
function handleError() {
    echo -e "Error in line: $1\tcommand: $2"
}

# ctrl_c: Handles SIGINT (Ctrl+C) to exit gracefully.
function ctrl_c() {
    echo -e "\n${RED}[+][+][+] Exiting the program ... [+][+][+]${ENDCOLOR}"
    sleep 2
    exit 0
}

# updateCounts: Increments counters for severity, facility, and their combination.
# Arguments:
#   $1 - Severity key (e.g., "err")
#   $2 - Facility key (e.g., "daemon")
function updateCounts() {
    local sevKey="$1"
    local facKey="$2"

    ((sevCountArr["$sevKey"]++))
    ((facCountArr["$facKey"]++))
    ((sevFacCountArr["$sevKey:$facKey"]++))
}

# printFinalReport: Generates and prints the final log analysis report.
function printFinalReport {
    # Final parsed log messages with decoded PRI values.
    echo
    echo
    echo -e " ${BLUE}---------------    LOG MESSAGES (PRI DECODED)    ---------------${ENDCOLOR}"
    echo

    printf " ${MAGENTA}%-8s${ENDCOLOR} ${WHITE}%-10s${ENDCOLOR} ${YELLOW}%-23s${ENDCOLOR} %s${ENDCOLOR}\n" "SEVERITY" "FACILITY" "DATE" "MESSAGE"
    echo

    # Overwrite the output file with a clean slate for this run.
    : >"log_parsed.txt"

    # Iterate through all valid logs to print them to console and file.
    for ((i = 0; i < global_valid_logs; i++)); do
        # Print to console with color codes.
        printf " ${MAGENTA}%-8s${ENDCOLOR} ${WHITE}%-10s${ENDCOLOR} ${YELLOW}%s${ENDCOLOR} %s\n" "${sevKeyMsg[$i]}" "${facKeyMsg[$i]}" "${dateMsg[$i]}" "${log_msgMsg[$i]}"
        # Print to file without color codes. The '>>' appends each line.
        printf " %-8s %-10s %s %s\n" "${sevKeyMsg[$i]}" "${facKeyMsg[$i]}" "${dateMsg[$i]}" "${log_msgMsg[$i]}" >>"log_parsed.txt"
    done

    # Check if the output file was successfully created.
    if [ -f "log_parsed.txt" ]; then
        global_outfile_msg=" ${YELLOW}A copy of the log messages, parsed with severity and facility indicators, has been saved to${ENDCOLOR}${WHITE} 'log_parsed.txt'${ENDCOLOR}${YELLOW}. This makes it easy to filter using${ENDCOLOR} 'grep' command${YELLOW} by severity or facility${ENDCOLOR} (e.g., grep 'err' log_parsed.txt)"
    else
        global_outfile_msg=" ${RED}Failed to create output file:${ENDCOLOR} ${WHITE}'log_parsed.txt'.${ENDCOLOR}"
    fi

    echo
    echo
    echo
    # --- Counts by Severity ---
    echo -e " ${MAGENTA}---------------    COUNTS BY SEVERITY    ---------------${ENDCOLOR}"
    echo
    for ((i = 0; i < ${#sevArr[@]}; i++)); do
        sevKey="${sevArr[$i]}"
        sevCount="${sevCountArr[$sevKey]:-0}"
        printf " ${MAGENTA}%-8s${ENDCOLOR}%-5s" "${sevKey}:" "${sevCount}"
    done
    echo
    echo
    echo

    # --- Counts by Facility (Efficiently piped to column) ---
    echo -e " ${WHITE}---------------    COUNTS BY FACILITY    ---------------${ENDCOLOR}"
    echo
    {
        for facKey in "${facArr[@]}"; do
            facCount="${facCountArr[$facKey]:-0}"
            echo " ${facKey}: ${facCount}"
        done
    } | column -x
    echo
    echo
    echo

    # --- Table for Facility/Severity Breakdown ---
    echo -e " ${YELLOW}---------------    TABLE FACILITY/SEVERITY BREAKDOWN    ---------------${ENDCOLOR}"
    echo
    local term_width
    term_width=$(tput cols)
    local n_fac=${#facArr[@]}
    local col_width
    col_width=$((term_width / (n_fac + 3)))

    echo -e "  ${BLUE}Facility →${ENDCOLOR}"
    # Header row for facilities.
    printf "${RED}%-${col_width}s${ENDCOLOR}|" "Severity↓"
    for ((i = 0; i < n_fac; i++)); do
        fac="${facArr[$i]}"
        printf "${BLUE}%-${col_width}s${ENDCOLOR}" "  $fac"
    done
    echo
    # Separator line.
    printf '%*s' $((col_width)) '' | tr ' ' '-'
    printf "+"
    for ((i = 0; i < n_fac; i++)); do
        printf '%*s' $((col_width)) '' | tr ' ' '-'
    done
    echo
    # Data rows.
    for sev in "${sevArr[@]}"; do
        printf "${RED}%-${col_width}s${ENDCOLOR}|" " $sev"
        for ((i = 0; i < n_fac; i++)); do
            fac="${facArr[$i]}"
            val="${sevFacCountArr["$sev:$fac"]:-0}"
            printf "${GRAY}%-${col_width}s${ENDCOLOR}" "      $val"
        done
        echo
    done

    echo
    echo
    echo -e "${global_outfile_msg}"
    echo
    echo
    echo -e " ---------------    ${RED}REPORT FINISHED${ENDCOLOR}    ---------------"
    echo
}

# parseLog: Extracts severity, facility, date, and message from a log line.
# Argument:
#   $1 - A syslog line to parse.
# Returns:
#   string - A pipe-separated string with the parsed fields.
function parseLog() {
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
    last_fac_index=$((${#facArr[@]} - 1))

    if [ "$fac" -ge 0 ] && [ "$fac" -le "$last_fac_index" ]; then
        facKey="${facArr[$fac]}"
    else
        facKey="${facArr[$last_fac_index]}"
    fi

    echo -e "${sevKey}|${facKey}|${date}|${log_msg}"
}

# checkFile: Validates the input file and processes its logs.
# Arguments:
#   $1 - Path to the log file.
function checkFile() {
    local file_path="$1"
    local file_name
    file_name="$(basename "${file_path}")"
    local regex='^[<][0-9]+>1[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+(-|[[^]]+])[[:space:]]+(.*)?'

    if [ ! -f "${file_path}" ]; then
        echo -e "❌ The file does not exist or is empty."
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

            # Storing parsed elements for the final report.
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
    echo -e " ${RED}---------------    LOG MANAGER REPORT    ---------------${ENDCOLOR}"
    echo
    echo -e " ${YELLOW}Analyzed file name:${ENDCOLOR} ${WHITE}${file_name}${ENDCOLOR}"
    echo " ${line_number} logs analyzed"
    echo " Valid: ${global_valid_logs} logs"

    local oldIFS=$IFS
    if [ ${#unknownLogs[@]} -eq 0 ]; then
        local joinedUnknown="---"
    else
        IFS=',' joinedUnknown="${unknownLogs[*]}"
    fi
    IFS="$oldIFS"

    echo -e " ${RED}Invalid: ${invalid_logs} logs${ENDCOLOR}"
    echo -e " ${RED}Invalid format log entries found in input file at line number(s): ${joinedUnknown}${ENDCOLOR}"
    echo
}

# main: Entry point of the script.
# Arguments:
#   $@ - All arguments passed to the script (e.g., the log file path).
function main() {
    # Check if a log file path is provided
    if [ $# -ne 1 ]; then
        echo
        echo -e "${RED}Usage: $0 <log_file_path>${ENDCOLOR}"
        echo -e "${YELLOW}Please provide a log file to analyze.${ENDCOLOR}"
        echo
        exit 1
    fi

    checkFile "$1"
    printFinalReport
    return 0
}

# --- Main script execution starts here ---
trap 'handleError "${LINENO}" "${BASH_COMMAND}"' ERR
trap ctrl_c INT

# Severity and Facility arrays for decoding.
sevArr=("emerg" "alert" "crit" "err" "warn" "notice" "info" "debug")
facArr=("kern" "user" "mail" "daemon" "auth" "syslog" "lpr" "news" "uucp" "cron" "authpriv" "ftp" "ntp" "audit" "alert" "reserved" "[Unknown]")

# Global arrays for parsed logs and unknown lines.
declare -a unknownLogs sevKeyMsg facKeyMsg dateMsg log_msgMsg

# Global associative arrays for counting.
declare -A sevCountArr facCountArr sevFacCountArr

# Global variables.
declare -g global_valid_logs=0
declare -g global_outfile_msg=""

main "$@"
