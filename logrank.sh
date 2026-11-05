#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "failed at line $LINENO" >&2' ERR

if [ $# -lt 2 ]; then
    echo "Usage: $0 <logfile|-> <SEVERITY> [SEVERITY...]" >&2
    echo "SEVERITY: WARN ERROR INFO"
    exit 1
fi

SOURCE="$1"
shift

TMP_FILE=""
if [ "$SOURCE" = "-" ]; then
    TMP_FILE=$(mktemp)
    trap 'rm -f "$TMP_FILE"' EXIT
    cat > "$TMP_FILE"
    LOG_FILE="$TMP_FILE"
else
    LOG_FILE="$SOURCE"
fi

rank_patterns() {
    local severity="$1"

    echo "${severity} patterns:"
    grep -w "$severity" "$LOG_FILE" \
        | tr -d '\r' \
        | tr -s ' ' \
        | cut -d' ' -f4- \
        | sed "s/'[^']*'/<N>/g" \
        | sed "s/[0-9][0-9]*/<N>/g" \
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
