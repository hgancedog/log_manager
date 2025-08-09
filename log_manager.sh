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
    sleep 1
    exit 0
}

function checkFile () {

    local file_path="$1"
    local regex='^[<][0-9]+>1[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+(-|[[^]]+])[[:space:]]+(.*)?'

    if [ ! -f "$file_path" ]; then
        echo "❌ El archivo no existe o está vacío."
        return 1
    fi

    awk -v regex="$regex" '
      BEGIN {
        valid = 0;
        invalid = 0;

        # Arrays for human-readable severity and facility names
        split("emerg alert crit err warning notice info debug", sevArray, " ");
        numFac = split("kern user mail daemon auth syslog lpr news uucp cron authpriv ftp ntp security console clock", facArray, " ");
      }

      {
        if ($0 ~ regex) {
          valid++;

          # Extract PRI from <nn>
          match($0, /<([0-9]+)>/, m);
          if (m[1]) {
            pri = m[1] + 0;
            severity = pri % 8;
            facility = int(pri / 8);

            sevKey = sevArray[severity + 1];
            facKey = (facility + 1 <= numFac) ? facArray[facility + 1] : "unknown";

            # Counting by key
            severityCount[sevKey]++;
            facilityCount[facKey]++;
            sevFacCount[sevKey "|" facKey]++;

            msgStart = index($0, "- -");
            if (msgStart > 0 && msgStart + 4 <= length($0)) {
              logMsg = substr($0, msgStart + 4);
            } else {
              logMsg = "[no message]";
            }

            printf "%d\tSeverity: %s\tFacility: %s\t%s\n", severity, sevKey, facKey, logMsg;
          } else {
            print "⚠️ PRI not found:", $0;
          }
        } else {
          invalid++;
          print "❌ Invalid line:", $0;
        }
      }

      END {
        print "\n📊 Report:";
        print "Valid lines:", valid;
        print "Invalid lines:", invalid;

        print "\n🔢 Severities:";
        for (i = 0; i < 8; i++) {
            sev = sevArray[i + 1];
            count = (sev in severityCount) ? severityCount[sev] : 0;
            printf "  %s: %d\n", sev, count;
        }

        print "\n🏢 Facilities:";
        for (i = 0; i < numFac; i++) {
            fac = facArray[i + 1];
            count = (fac in facilityCount) ? facilityCount[fac] : 0;
            printf "  %s: %d\n", fac, count;
        }
      }

  ' "$file_path" > temp.out

  grep '^[0-9]' temp.out | sort -n | cut -f2-
  grep -v '^[0-9]' temp.out
  [ -f temp.out ] && rm temp.out
 }

function main() {
    
    checkFile "$1"
 
    return 0
}

trap 'handleError "${LINENO}" "${BASH_COMMAND}"' ERR #if there are functions, to add stack trace!

trap ctrl_c INT

main "$@"

