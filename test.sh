#!/bin/bash
set -euo pipefail

function prueba() {
    local line_number=0
    while IFS= read -r line || [ -n "$line" ]; do
        ((line_number++))
        echo "Línea $line_number: $line"
    done < "$1"
}

prueba "$1"

