#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "failed at line $LINENO" >&2' ERR

usage() {
    echo "Usage: $0 [logfile|-] <SEVERITY> [SEVERITY...]" >&2
    echo "SEVERITY: WARN ERROR INFO DEBUG" >&2
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

# first argument severity
if [[ "$1" =~ ^(WARN|ERROR|INFO|DEBUG)$ ]]; then
    SOURCE="-"
else
    SOURCE="$1"
    shift
fi

if [ $# -lt 1 ]; then
    usage
fi

TMP_FILE=""
if [ "$SOURCE" = "-" ]; then
    TMP_FILE=$(mktemp)
    trap 'rm -f "$TMP_FILE"' EXIT
    cat > "$TMP_FILE"
    LOG_FILE="$TMP_FILE"
else
    LOG_FILE="$SOURCE"

    if [ ! -f "$LOG_FILE" ] || [ ! -r "$LOG_FILE" ]; then
        echo "Error: Cannot read log file: $LOG_FILE" >&2
        exit 1
    fi
fi

rank_patterns() {
    local severity="$1"

    echo "${severity} patterns:"

    awk -v severity="$severity" '
        $3 == severity {
            $1 = $2 = $3 = ""
            sub(/^[[:space:]]+/, "")
            print
        }
    ' "$LOG_FILE" \
        | tr -d '\r' \
        | tr -s ' ' \
        | sed -E \
            -e "s/'[^']*'/<N>/g" \
            -e 's/[0-9]+/<N>/g' \
        | sort \
        | uniq -c \
        | sort -rn \
        | while read -r count pattern; do
            echo "#$count $pattern"
        done
    echo
}

for severity in "$@"; do
    rank_patterns "$severity"
done
