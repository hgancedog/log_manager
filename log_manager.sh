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

    # awk -v regex="$regex" '
    #     $0 ~ regex { valid++ }
    #     $0 !~ regex { invalid++; print "Línea inválida:", $0 }
    #     { print $1 }
    #     END { print "Válidas:", valid; print "Inválidas:", invalid }
    # ' "$file_path"
    awk -v regex="$regex" '
      BEGIN {
        valid = 0;
        invalid = 0;

        # Arrays para nombres legibles de severity y facility
        split("emerg alert crit err warning notice info debug", sevArray, " ");
        numFac = split("kern user mail daemon auth syslog lpr news uucp cron authpriv ftp ntp security console solaris", facArray, " ");
      }

      {
        if ($0 ~ regex) {
          valid++;

          # Extraer PRI desde <nn>
          match($0, /<([0-9]+)>/, m);
          if (m[1]) {
            pri = m[1] + 0;
            severity = pri % 8;
            facility = int(pri / 8);

            severityStr = sevArray[severity + 1];
            facilityStr = (facility + 1 <= numFac) ? facArray[facility + 1] : "desconocido";

            msgStart = index($0, "- -");
            if (msgStart > 0 && msgStart + 4 <= length($0)) {
              logMsg = substr($0, msgStart + 4);
            } else {
              logMsg = "[sin mensaje]";
            }

            printf "%d\tSeverity: %s\tFacility: %s\t%s\n", severity, severityStr, facilityStr, logMsg;
          } else {
            print "⚠️ PRI no encontrado:", $0;
          }
        } else {
          invalid++;
          print "❌ Línea inválida:", $0;
        }
      }

      END {
        print "\n📊 Resumen:";
        print "Válidas:", valid;
        print "Inválidas:", invalid;
      }
' "$file_path" | sort -n
 }

function main() {
    
    echo "Starting main function"

    checkFile "$1"
 
    return 0
}

trap 'handleError "${LINENO}" "${BASH_COMMAND}"' ERR #if there are functions, to add stack trace!

trap ctrl_c INT

echo "Shell declarada (por \$SHELL): $SHELL"
echo "Shell usada por el script (por \$0): $0"
echo "Comando ejecutándose (por ps):"
ps -p $$ -o args=

echo "Imprimiendo prueba por pantalla"

main "$@"

